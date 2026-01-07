import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class ExpensesSummaryHeader extends ConsumerStatefulWidget {
  final AsyncValue<Map<String, ({double total, int color})>> chartData;
  final AsyncValue<double> projectedTotal;
  final AsyncValue<double> executedTotal;

  const ExpensesSummaryHeader({
    super.key,
    required this.chartData,
    required this.projectedTotal,
    required this.executedTotal,
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
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SummaryCard(
                  title: "Gastado (real)",
                  amountAsync: widget.executedTotal,
                  color: colors.error,
                ),
                const Gap(12),
                _SummaryCard(
                  title: "Proyectado del mes",
                  amountAsync: widget.projectedTotal,
                  color: colors.primary,
                ),
              ],
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: colors.surfaceContainer, border: Border.all(color: colors.outlineVariant.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
          const Gap(4),
          amountAsync.when(
            data: (amount) => Text(currencyFormat.format(amount), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
            loading: () => const SizedBox(height: 24, child: LinearProgressIndicator()),
            error: (e, s) => Text("Error", style: TextStyle(color: colors.error)),
          ),
        ],
      ),
    );
  }
}