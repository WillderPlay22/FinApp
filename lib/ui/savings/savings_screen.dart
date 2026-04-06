import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:finapp/logic/providers/currency_providers.dart';
import '../../config/theme/app_colors.dart';
import '../home/widgets/glass_card.dart';
import 'savings_providers.dart';
import 'widgets/savings_list.dart';
import 'modals/add_saving_modal.dart';

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = AppColors.of(context);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Mis Ahorros',
          style: TextStyle(
            color: appColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: appColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          _SavingsHeader(appColors: appColors),
          const Gap(4),
          const Expanded(child: SavingsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (_) => const AddSavingModal(),
          );
        },
        backgroundColor: appColors.savingsColor,
        foregroundColor: Colors.white,
        icon: const Icon(FontAwesomeIcons.plus, size: 16),
        label: const Text('Nuevo Ahorro',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _SavingsHeader extends ConsumerWidget {
  final AppColors appColors;

  const _SavingsHeader({required this.appColors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAsync = ref.watch(totalSavedProvider);
    final progressAsync = ref.watch(monthlySavingsProgressProvider);
    final isMultiCurrency = ref.watch(isMultiCurrencyEnabledProvider);
    final rateAsync = ref.watch(currentExchangeRateProvider);

    final currencyFormat =
        NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 2);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: GlassCard(
        accentColor: appColors.savingsColor,
        borderRadius: 20,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // — Total ahorrado —
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: appColors.savingsColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(FontAwesomeIcons.vault,
                      color: appColors.savingsColor, size: 20),
                ),
                const Gap(14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Ahorrado',
                        style: TextStyle(
                          color: appColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Gap(2),
                      totalAsync.when(
                        data: (total) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currencyFormat.format(total),
                              style: TextStyle(
                                color: appColors.savingsColor,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (isMultiCurrency)
                              rateAsync.when(
                                data: (rate) {
                                  if (rate == null) return const SizedBox.shrink();
                                  return Text(
                                    'Bs. ${NumberFormat('#,##0.00', 'es').format(total * rate.rate)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: appColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                },
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              ),
                          ],
                        ),
                        loading: () => Text(
                          '\$0.00',
                          style: TextStyle(
                            color: appColors.savingsColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Gap(16),
            Divider(color: appColors.textSecondary.withAlpha(40), height: 1),
            const Gap(16),

            // — Progreso mensual —
            progressAsync.when(
              data: (data) {
                final progress =
                    data.expected > 0 ? (data.executed / data.expected) : 0.0;
                final clampedProgress = progress.clamp(0.0, 1.0);

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progreso Mensual',
                          style: TextStyle(
                            color: appColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: appColors.savingsColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${data.executedPlans}/${data.totalPlans} Cuotas',
                            style: TextStyle(
                              color: appColors.savingsColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: clampedProgress),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (_, value, __) => LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          backgroundColor:
                              appColors.textSecondary.withAlpha(30),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress > 1.0
                                ? const Color(0xFFFFD600)
                                : appColors.savingsColor,
                          ),
                        ),
                      ),
                    ),
                    const Gap(8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${data.executed.toStringAsFixed(0)} ejecutado',
                          style: TextStyle(
                            color: appColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Meta: \$${data.expected.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: appColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const SizedBox(height: 40),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
