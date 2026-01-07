import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class ExpensesSummaryHeader extends ConsumerStatefulWidget {
  final bool isCategoryView;
  final AsyncValue<Map<String, ({double total, int color})>> chartData;
  final AsyncValue<double> projectedTotal;
  final AsyncValue<double> executedTotal;
  final AsyncValue<double> historyTotal;

  const ExpensesSummaryHeader({
    super.key,
    required this.isCategoryView,
    required this.chartData,
    required this.projectedTotal,
    required this.executedTotal,
    required this.historyTotal,
  });

  @override
  ConsumerState<ExpensesSummaryHeader> createState() => _ExpensesSummaryHeaderState();
}

class _ExpensesSummaryHeaderState extends ConsumerState<ExpensesSummaryHeader> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // --- GRÁFICO DE DONA ---
          SizedBox(
            width: 150,
            height: 150,
            child: widget.chartData.when(
              data: (data) => _buildChart(context, data),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => const Center(child: Icon(Icons.error_outline)),
            ),
          ),
          const Gap(16),
          // --- TARJETAS DE TOTALES ---
          // ✅ Usamos AnimatedSwitcher para animar el cambio entre la vista de 2 tarjetas y 1 tarjeta.
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              // Una transición que combina desvanecimiento y deslizamiento.
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.3),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: widget.isCategoryView
                  // VISTA PARA LA PESTAÑA "CATEGORÍAS" (2 tarjetas)
                  ? Column(
                      key: const ValueKey('category_cards'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SummaryCard(
                          title: "Gastado (real)",
                          amountAsync: widget.executedTotal,
                          color: colors.error, // Rojo para gastos
                        ),
                        const Gap(12),
                        _SummaryCard(
                          title: "Proyectado del mes",
                          amountAsync: widget.projectedTotal,
                          color: colors.primary, // Azul/Morado para proyección
                        ),
                      ],
                    )
                  // VISTA PARA LA PESTAÑA "HISTORIAL" (1 tarjeta)
                  : Center(
                      key: const ValueKey('history_card'),
                      child: _SummaryCard(title: "Total del Periodo", amountAsync: widget.historyTotal, color: colors.tertiary), // Otro color para el total
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, Map<String, ({double total, int color})> data) {
    final totalValue = data.values.fold(0.0, (sum, e) => sum + e.total);
    final List<PieChartSectionData> sections = [];
    
    int i = 0;
    for (var entry in data.entries) {
      final isTouched = i == touchedIndex;
      final radius = isTouched ? 35.0 : 25.0;
      final value = entry.value;

      sections.add(PieChartSectionData(
        value: value.total,
        color: Color(value.color),
        title: '', // ✅ Se elimina el texto del porcentaje como fue solicitado.
        radius: radius,
      ));
      i++;
    }

    if (sections.isEmpty) {
      return PieChart(
        PieChartData(
          sections: [PieChartSectionData(value: 1, color: Theme.of(context).colorScheme.surfaceVariant, title: '', radius: 25)],
          centerSpaceRadius: 45,
          sectionsSpace: 2,
        ),
        // Animamos también el estado vacío para una transición suave.
        swapAnimationDuration: const Duration(milliseconds: 800),
        swapAnimationCurve: Curves.easeInOutCubic,
      );
    }

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                touchedIndex = -1;
                return;
              }
              touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        sections: sections,
        centerSpaceRadius: 45,
        sectionsSpace: 2,
      ),
      // ✅ ¡AQUÍ ESTÁ LA MAGIA!
      // Estas propiedades controlan la animación cuando los datos del gráfico cambian.
      // Aumentamos la duración para que la transición sea más lenta y apreciable.
      swapAnimationDuration: const Duration(milliseconds: 800), // Antes era el default (150ms), ahora es más lento.
      // Usamos una curva suave para que la animación se vea fluida.
      swapAnimationCurve: Curves.easeInOutCubic,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final AsyncValue<double> amountAsync;
  final Color color;

  const _SummaryCard({required this.title, required this.amountAsync, required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 2);

    // ✅ Se envuelve en un Container con constraints para asegurar tamaños consistentes.
    return Container(
      width: double.infinity, // Asegura que ocupe todo el ancho disponible
      constraints: const BoxConstraints(minHeight: 74), // Altura mínima para consistencia
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        // ✅ Se añade un borde izquierdo con el color temático para darle énfasis.
        border: Border(
          left: BorderSide(
            color: color,
            width: 5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center, // Centra el contenido verticalmente
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
          const Gap(4),
          amountAsync.when(
            data: (amount) => Text(currencyFormat.format(amount), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
            loading: () => const SizedBox(height: 24, child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)))),
            error: (e, s) => Text("Error", style: TextStyle(color: colors.error)),
          ),
        ],
      ),
    );
  }
}