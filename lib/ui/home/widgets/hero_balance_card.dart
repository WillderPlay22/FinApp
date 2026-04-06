import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import '../../../config/theme/app_colors.dart';
import '../home_providers.dart';
import 'glass_card.dart';

class HeroBalanceCard extends ConsumerStatefulWidget {
  const HeroBalanceCard({super.key});

  @override
  ConsumerState<HeroBalanceCard> createState() => _HeroBalanceCardState();
}

class _HeroBalanceCardState extends ConsumerState<HeroBalanceCard> {
  bool _animate = false;
  double _displayedAmount = 0.0;

  static final _currencyFormat =
      NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _animate = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(homeSummaryDataProvider);
    final previousAsync = ref.watch(previousPeriodSummaryProvider);
    final appColors = AppColors.of(context);

    ref.listen<SummaryFilter>(summaryFilterProvider, (prev, next) {
      if (prev != next && mounted) {
        setState(() => _animate = false);
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) setState(() => _animate = true);
        });
      }
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: summaryAsync.when(
        loading: () => GlassCard(
          borderRadius: 20,
          child: SizedBox(
            height: 120,
            child: Center(
              child: CircularProgressIndicator(color: appColors.primary),
            ),
          ),
        ),
        error: (_, __) => GlassCard(
          borderRadius: 20,
          child: SizedBox(
            height: 120,
            child: Center(
              child: Text('Error al cargar datos',
                  style: TextStyle(color: appColors.textSecondary)),
            ),
          ),
        ),
        data: (data) {
          final animData = _animate
              ? data
              : (income: 0.0, expenses: 0.0, debts: 0.0, available: 0.0);

          // Delta calculation
          double? deltaPercent;
          final prev = previousAsync.value;
          if (prev != null && prev.available > 0) {
            deltaPercent =
                ((data.available - prev.available) / prev.available) * 100;
          }

          if (_animate &&
              data.income == 0 &&
              data.expenses == 0 &&
              data.debts == 0) {
            return GlassCard(
              borderRadius: 20,
              child: SizedBox(
                height: 120,
                child: Center(
                  child: Text('Sin datos para proyectar',
                      style: TextStyle(color: appColors.textSecondary)),
                ),
              ),
            );
          }

          return GlassCard(
            borderRadius: 20,
            accentColor: appColors.primary,
            child: Row(
              children: [
                // Left side: Balance info
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Disponible',
                        style: TextStyle(
                          color: appColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const Gap(4),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: _displayedAmount, end: animData.available),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutSine,
                        builder: (context, value, _) {
                          _displayedAmount = value;
                          return Text(
                            _currencyFormat.format(value),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: appColors.textPrimary,
                              letterSpacing: -1.5,
                            ),
                          );
                        },
                      ),
                      if (deltaPercent != null) ...[
                        const Gap(8),
                        _DeltaBadge(percentage: deltaPercent),
                      ],
                    ],
                  ),
                ),
                // Right side: Mini donut
                SizedBox(
                  width: 110,
                  height: 110,
                  child: PieChart(
                    PieChartData(
                      sections: _buildSections(animData, appColors),
                      centerSpaceRadius: 38,
                      sectionsSpace: 3,
                      startDegreeOffset: 270,
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 800),
                    swapAnimationCurve: Curves.easeInOutCubic,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
    ({double income, double expenses, double debts, double available}) data,
    AppColors colors,
  ) {
    final sections = <PieChartSectionData>[];

    if (data.income > 0) {
      sections.add(PieChartSectionData(
        value: data.income,
        color: colors.incomeColor,
        radius: 18,
        showTitle: false,
        borderSide: BorderSide(
            color: colors.incomeColor.withOpacity(0.4), width: 3),
      ));
    }
    if (data.expenses > 0) {
      sections.add(PieChartSectionData(
        value: data.expenses,
        color: colors.expenseColor,
        radius: 18,
        showTitle: false,
        borderSide: BorderSide(
            color: colors.expenseColor.withOpacity(0.4), width: 3),
      ));
    }
    if (data.debts > 0) {
      sections.add(PieChartSectionData(
        value: data.debts,
        color: colors.debtColor,
        radius: 18,
        showTitle: false,
        borderSide: BorderSide(
            color: colors.debtColor.withOpacity(0.4), width: 3),
      ));
    }

    if (sections.isEmpty) {
      sections.add(PieChartSectionData(
        value: 1,
        color: colors.borderSubtle.withOpacity(0.3),
        radius: 14,
        showTitle: false,
      ));
    }

    return sections;
  }
}

class _DeltaBadge extends StatelessWidget {
  final double percentage;

  const _DeltaBadge({required this.percentage});

  @override
  Widget build(BuildContext context) {
    final isPositive = percentage >= 0;
    final color = isPositive
        ? AppColors.of(context).incomeColor
        : AppColors.of(context).expenseColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? '+' : ''}${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
