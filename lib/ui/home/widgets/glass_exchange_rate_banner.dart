import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/app_colors.dart';
import '../../../logic/providers/currency_providers.dart';
import 'glass_card.dart';

class GlassExchangeRateBanner extends ConsumerWidget {
  const GlassExchangeRateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rateAsync = ref.watch(currentExchangeRateProvider);
    final appColors = AppColors.of(context);

    return rateAsync.when(
      data: (rate) {
        if (rate == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GlassCard(
            borderRadius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.currency_exchange,
                    size: 14, color: appColors.primary),
                const SizedBox(width: 8),
                Text(
                  '1 USD = ${rate.rate.toStringAsFixed(2)} BS',
                  style: TextStyle(
                    color: appColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${rate.source})',
                  style: TextStyle(
                    color: appColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
