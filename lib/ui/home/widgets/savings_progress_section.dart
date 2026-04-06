import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../config/theme/app_colors.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/saving.dart';
import '../home_providers.dart';
import 'glass_card.dart';

class SavingsProgressSection extends ConsumerWidget {
  const SavingsProgressSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savingsAsync = ref.watch(homeSavingsProvider);
    final appColors = AppColors.of(context);

    return savingsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (savings) {
        if (savings.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GlassCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mis Ahorros',
                  style: TextStyle(
                    color: appColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(12),
                ...savings.take(3).map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SavingTile(saving: s),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SavingTile extends StatelessWidget {
  final Saving saving;

  const _SavingTile({required this.saving});

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final color = Color(saving.colorValue);
    final currencyFormat =
        NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 0);
    final isGoal = saving.type == SavingType.goal;
    final progress = isGoal && saving.targetAmount != null && saving.targetAmount! > 0
        ? (saving.currentAmount / saving.targetAmount!).clamp(0.0, 1.0)
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: FaIcon(
                IconData(saving.iconCode, fontFamily: 'FontAwesomeSolid', fontPackage: 'font_awesome_flutter'),
                size: 14,
                color: color,
              ),
            ),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  saving.name,
                  style: TextStyle(
                    color: appColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (progress != null) ...[
                  const Gap(4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 4,
                          backgroundColor: color.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const Gap(8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(saving.currentAmount),
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isGoal && saving.targetAmount != null)
                Text(
                  '/ ${currencyFormat.format(saving.targetAmount)}',
                  style: TextStyle(
                    color: appColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
