import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../config/theme/app_colors.dart';
import '../home_providers.dart';
import 'glass_card.dart';

class PeriodComparisonCard extends ConsumerWidget {
  const PeriodComparisonCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAsync = ref.watch(homeSummaryDataProvider);
    final previousAsync = ref.watch(previousPeriodSummaryProvider);
    final appColors = AppColors.of(context);

    final current = currentAsync.value;
    final previous = previousAsync.value;

    if (current == null || previous == null) return const SizedBox.shrink();

    final currencyFormat =
        NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Comparacion de Periodos',
                  style: TextStyle(
                    color: appColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(Icons.compare_arrows,
                    size: 16, color: appColors.textSecondary),
              ],
            ),
            const Gap(16),
            Row(
              children: [
                Expanded(
                  child: _PeriodColumn(
                    label: 'Anterior',
                    income: previous.income,
                    expenses: previous.expenses + previous.debts,
                    appColors: appColors,
                    format: currencyFormat,
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: appColors.borderSubtle.withOpacity(0.3),
                ),
                Expanded(
                  child: _PeriodColumn(
                    label: 'Actual',
                    income: current.income,
                    expenses: current.expenses + current.debts,
                    appColors: appColors,
                    format: currencyFormat,
                  ),
                ),
              ],
            ),
            const Gap(12),
            // Delta bars
            _DeltaRow(
              label: 'Ingresos',
              previousVal: previous.income,
              currentVal: current.income,
              color: appColors.incomeColor,
            ),
            const Gap(6),
            _DeltaRow(
              label: 'Gastos',
              previousVal: previous.expenses + previous.debts,
              currentVal: current.expenses + current.debts,
              color: appColors.expenseColor,
              invertSign: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodColumn extends StatelessWidget {
  final String label;
  final double income;
  final double expenses;
  final AppColors appColors;
  final NumberFormat format;

  const _PeriodColumn({
    required this.label,
    required this.income,
    required this.expenses,
    required this.appColors,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: appColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(8),
        Text(
          format.format(income),
          style: TextStyle(
            color: appColors.incomeColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Gap(2),
        Text(
          format.format(expenses),
          style: TextStyle(
            color: appColors.expenseColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _DeltaRow extends StatelessWidget {
  final String label;
  final double previousVal;
  final double currentVal;
  final Color color;
  final bool invertSign;

  const _DeltaRow({
    required this.label,
    required this.previousVal,
    required this.currentVal,
    required this.color,
    this.invertSign = false,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    double change = 0;
    if (previousVal > 0) {
      change = ((currentVal - previousVal) / previousVal) * 100;
    }
    if (invertSign) change = -change;

    final isPositive = change >= 0;
    final changeColor = isPositive ? appColors.incomeColor : appColors.expenseColor;

    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(color: appColors.textSecondary, fontSize: 11),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: previousVal > 0
                  ? (currentVal / previousVal).clamp(0.0, 2.0) / 2.0
                  : 0.5,
              minHeight: 4,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.6)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${isPositive ? '+' : ''}${change.toStringAsFixed(0)}%',
          style: TextStyle(
            color: changeColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
