import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class ExpensesSummaryHeader extends ConsumerStatefulWidget {
  final int tabIndex; // Cambiado de bool a int
  final AsyncValue<Map<String, ({double total, int color})>> chartData;
  final AsyncValue<double> projectedTotal;
  final AsyncValue<double> executedTotal;
  final AsyncValue<double> historyTotal;

  const ExpensesSummaryHeader({
    super.key,
    required this.tabIndex,
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
    return Container(
      padding: const EdgeInsets.all(16.0),
      // ✅ AUMENTADO: De 160 a 190 para evitar el overflow con títulos largos.
      // Esto soluciona el error "RenderFlex overflowed" y hace que el círculo vuelva a aparecer.
      child: SizedBox(
        height: 190,
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
                child: _buildCardsForTab(widget.tabIndex),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para construir las tarjetas según la pestaña
  Widget _buildCardsForTab(int index) {
    switch (index) {
      // Pestaña "Categorías"
      case 0:
        return Column(
          key: const ValueKey('category_cards'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SummaryCard(
              title: "Gastado",
              amountAsync: widget.executedTotal,
              color: const Color(0xFFFF6B6B), // Coral
            ),
            const Gap(12),
            _SummaryCard(
              title: "Proyectado del mes",
              amountAsync: widget.projectedTotal,
              color: const Color(0xFFFFA502), // Mandarina
            ),
          ],
        );
      // Pestaña "Deudas"
      case 1:
        return Column(
          key: const ValueKey('debts_cards'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SummaryCard(
              title: "MONTO TOTAL PAGADO",
              amountAsync: widget.executedTotal,
              color: const Color(0xFF1DD1A1), // Esmeralda
            ),
            const Gap(12),
            _SummaryCard(
              title: "MONTO TOTAL DE DEUDAS PENDIENTES",
              amountAsync: widget.projectedTotal,
              color: const Color(0xFFE17055), // Terracota
            ),
          ],
        );
      // Pestaña "Historial"
      case 2:
      default:
        return Center(
          key: const ValueKey('history_card'),
          child: _SummaryCard(
            title: "Total del Periodo",
            amountAsync: widget.historyTotal,
            color: const Color(0xFFFF6B6B), // Coral
            isEnlarged: true,
          ),
        );
    }
  }

  Widget _buildChart(BuildContext context, Map<String, ({double total, int color})> data) {
    final List<PieChartSectionData> sections = [];
    
    int i = 0;
    for (var entry in data.entries) {
      // ✅ CORRECCIÓN: Solo añadimos secciones si el valor es mayor a 0.
      // Si ambos son 0, la lista 'sections' quedará vacía y se mostrará el gráfico "vacío" (gris).
      if (entry.value.total <= 0) continue;

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
          sections: [PieChartSectionData(value: 1, color: Theme.of(context).colorScheme.surfaceContainerHighest, title: '', radius: 25)],
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
  final bool isEnlarged;

  const _SummaryCard({required this.title, required this.amountAsync, required this.color, this.isEnlarged = false});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currencyFormat = NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 2);

    return Container(
      width: double.infinity, // Asegura que ocupe todo el ancho disponible
      constraints: const BoxConstraints(minHeight: 80), // Aumentado ligeramente
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha((255 * 0.3).round()),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center, // Centra el contenido verticalmente
        children: [
          Text(
            title,
            style: textTheme.labelMedium?.copyWith(
              color: Colors.white.withAlpha((255 * 0.8).round()),
              fontWeight: FontWeight.bold,
              // Se agranda el título si la tarjeta es la principal
              fontSize: isEnlarged ? 14 : 12,
            ),
            textAlign: TextAlign.center, // Centrar texto para títulos largos
            maxLines: 2, // Permitir 2 líneas
            overflow: TextOverflow.ellipsis,
          ),
          Gap(isEnlarged ? 8 : 4), // Más espacio en la tarjeta grande
          amountAsync.when(
            data: (amount) => Text(
              currencyFormat.format(amount),
              style: TextStyle(fontSize: isEnlarged ? 26 : 20, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            // Se agranda el indicador de carga y el texto de error
            loading: () => SizedBox(height: isEnlarged ? 32 : 24, child: Center(child: SizedBox(width: isEnlarged ? 32 : 24, height: isEnlarged ? 32 : 24, child: const CircularProgressIndicator(strokeWidth: 3, color: Colors.white)))),
            error: (e, s) => const Text("Error", style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}