import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../config/theme/app_colors.dart';
import '../../../logic/providers/time_provider.dart';
import '../home_providers.dart';
import '../models/upcoming_payment.dart';
import 'glass_card.dart';

class UpcomingPaymentsSection extends ConsumerWidget {
  const UpcomingPaymentsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(upcomingPaymentsProvider);
    final appColors = AppColors.of(context);

    return paymentsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (payments) {
        if (payments.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GlassCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Proximos Pagos',
                  style: TextStyle(
                    color: appColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(12),
                ...payments.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _PaymentTile(payment: p),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PaymentTile extends ConsumerWidget {
  final UpcomingPayment payment;

  const _PaymentTile({required this.payment});

  String _relativeDateLabel(DateTime date, DateTime now) {
    final diff = date.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff <= 0) return 'Hoy';
    if (diff == 1) return 'Manana';
    return 'En $diff dias';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = AppColors.of(context);
    final now = ref.watch(nowProvider);
    final currencyFormat =
        NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 0);

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
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: payment.color,
              shape: BoxShape.circle,
            ),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.title,
                  style: TextStyle(
                    color: appColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _relativeDateLabel(payment.dueDate, now),
                  style: TextStyle(
                    color: appColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            currencyFormat.format(payment.amount),
            style: TextStyle(
              color: payment.color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
