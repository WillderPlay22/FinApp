import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/app_colors.dart';
import '../home_providers.dart';
import 'glass_card.dart';

class BudgetHealthBar extends ConsumerWidget {
  const BudgetHealthBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(budgetHealthProvider);
    final appColors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: healthAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (health) {
          return GlassCard(
            borderRadius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Text(
                  'Salud: ',
                  style: TextStyle(
                    color: appColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  health.label,
                  style: TextStyle(
                    color: health.color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: health.score),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 6,
                          backgroundColor:
                              appColors.borderSubtle.withOpacity(0.3),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(health.color),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
