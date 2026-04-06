import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../config/theme/app_colors.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/transaction.dart';
import '../../../logic/providers/time_provider.dart';
import '../home_providers.dart';
import 'glass_card.dart';

class RecentActivityFeed extends ConsumerWidget {
  const RecentActivityFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(recentTransactionsProvider);
    final appColors = AppColors.of(context);

    return txAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (transactions) {
        if (transactions.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GlassCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Actividad Reciente',
                  style: TextStyle(
                    color: appColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(12),
                ...transactions.map((tx) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _TransactionTile(transaction: tx),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  final FinancialTransaction transaction;

  const _TransactionTile({required this.transaction});

  String _relativeDate(DateTime date, DateTime now) {
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} dias';
    return DateFormat('d MMM', 'es').format(date);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = AppColors.of(context);
    final now = ref.watch(nowProvider);
    final currencyFormat =
        NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 0);

    final Color typeColor;
    final String sign;
    switch (transaction.type) {
      case TransactionType.income:
        typeColor = appColors.incomeColor;
        sign = '+';
        break;
      case TransactionType.expense:
        typeColor = appColors.expenseColor;
        sign = '-';
        break;
      case TransactionType.saving:
        typeColor = appColors.savingsColor;
        sign = '-';
        break;
    }

    final iconColor = Color(transaction.colorValue);
    final displayName = transaction.note.isNotEmpty
        ? transaction.note
        : transaction.categoryName;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                IconData(transaction.categoryIconCode, fontFamily: 'MaterialIcons'),
                size: 16,
                color: iconColor,
              ),
            ),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    color: appColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _relativeDate(transaction.date, now),
                  style: TextStyle(
                    color: appColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$sign${currencyFormat.format(transaction.amount)}',
            style: TextStyle(
              color: typeColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
