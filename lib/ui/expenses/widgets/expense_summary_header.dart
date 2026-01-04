import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import '../../../logic/providers/database_providers.dart';

class ExpenseSummaryHeader extends ConsumerWidget {
  const ExpenseSummaryHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseDao = ref.watch(expenseDaoProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // TARJETA 1: GASTADO REAL (Este Mes)
          Expanded(
            child: StreamBuilder<double>(
              stream: expenseDao.watchTotalExpenseThisMonth(),
              builder: (context, snapshot) {
                final total = snapshot.data ?? 0.0;
                return _SummaryCard(
                  title: "Ejecutado",
                  amount: total,
                  icon: FontAwesomeIcons.moneyBillTrendUp,
                  color: Colors.red,
                  isFilled: true,
                );
              },
            ),
          ),
          
          const Gap(12),

          // TARJETA 2: PROYECTADO
          const Expanded(
            child: _SummaryCard(
              title: "Proyectado",
              amount: 0.0, 
              icon: FontAwesomeIcons.chartLine,
              color: Colors.orange,
              isFilled: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final MaterialColor color;
  final bool isFilled;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.isFilled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = isFilled ? color.shade600 : theme.cardColor;
    final textColor = isFilled ? Colors.white : theme.colorScheme.onSurface;
    final subTextColor = isFilled ? Colors.white70 : theme.colorScheme.outline;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: isFilled ? null : Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: isFilled 
            ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: isFilled ? Colors.white : color),
              const Gap(8),
              Text(title, style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const Gap(10),
          Text(
            "\$ ${amount.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.w900, 
              color: textColor
            ),
          ),
          const Gap(4),
          Text(
            "Este mes",
            style: TextStyle(fontSize: 10, color: subTextColor),
          )
        ],
      ),
    );
  }
}