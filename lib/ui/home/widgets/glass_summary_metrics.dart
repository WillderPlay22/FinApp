import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../config/theme/app_colors.dart';
import '../home_providers.dart';
import '../../income/income_screen.dart';
import '../../expenses/expenses_screen.dart';
import '../../savings/savings_screen.dart';
import '../../savings/savings_providers.dart';
import 'glass_card.dart';

class GlassSummaryMetrics extends ConsumerWidget {
  const GlassSummaryMetrics({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(homeSummaryDataProvider);
    final data = summaryAsync.value ??
        (income: 0.0, expenses: 0.0, debts: 0.0, available: 0.0);
    final totalSaved = ref.watch(totalSavedProvider).value ?? 0.0;
    final appColors = AppColors.of(context);

    void push(Widget screen) {
      Navigator.of(context).push(_fadeSlideRoute(screen));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _GlassMetricCard(
                  title: 'Ingresos',
                  amount: data.income,
                  color: appColors.incomeColor,
                  icon: FontAwesomeIcons.moneyBillTrendUp,
                  onTap: () => push(const IncomeScreen()),
                ),
              ),
              const Gap(12),
              Expanded(
                child: _GlassMetricCard(
                  title: 'Gastos',
                  amount: data.expenses,
                  color: appColors.expenseColor,
                  icon: FontAwesomeIcons.receipt,
                  onTap: () => push(const ExpensesScreen()),
                ),
              ),
            ],
          ),
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: _GlassMetricCard(
                  title: 'Deudas',
                  amount: data.debts,
                  color: appColors.debtColor,
                  icon: FontAwesomeIcons.fileInvoiceDollar,
                  onTap: () => push(const ExpensesScreen()),
                ),
              ),
              const Gap(12),
              Expanded(
                child: _GlassMetricCard(
                  title: 'Ahorro',
                  amount: totalSaved,
                  color: appColors.savingsColor,
                  icon: FontAwesomeIcons.piggyBank,
                  onTap: () => push(const SavingsScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassMetricCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _GlassMetricCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  static final _currencyFormat =
      NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        enableBlur: false,
        accentColor: color,
        borderRadius: 100,
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 66,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(icon, size: 12, color: color),
                  const Gap(6),
                  Text(
                    title,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.8),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const Gap(6),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: amount),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutSine,
                builder: (context, value, _) {
                  return Text(
                    _currencyFormat.format(value),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Transición: desvanecer + deslizar hacia arriba al entrar,
//               desvanecer + deslizar hacia abajo al salir. ──────────────

PageRouteBuilder<T> _fadeSlideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      final slide = Tween<Offset>(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}
