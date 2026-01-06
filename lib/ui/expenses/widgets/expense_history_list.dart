import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../data/models/transaction.dart';
import '../../../logic/providers/database_providers.dart';

class ExpenseHistoryList extends ConsumerWidget {
  const ExpenseHistoryList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseDao = ref.watch(expenseDaoProvider);
    final colors = Theme.of(context).colorScheme;

    return StreamBuilder<List<FinancialTransaction>>(
      stream: expenseDao.watchExpenseHistory(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Error al cargar historial"));

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FontAwesomeIcons.ghost, size: 50, color: colors.outlineVariant),
                const Gap(10),
                const Text("No hay gastos registrados aún."),
              ],
            ),
          );
        }

        final transactions = snapshot.data!;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          separatorBuilder: (c, i) => const Gap(12),
          itemBuilder: (context, index) {
            final tx = transactions[index];
            
            // ✅ ENVUELTO EN DISMISSIBLE PARA BORRAR DESLIZANDO
            return Dismissible(
              key: Key(tx.id.toString()),
              direction: DismissDirection.endToStart,
              background: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("¿Borrar transacción?"),
                    content: const Text("Esta acción no se puede deshacer."),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Borrar", style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
              },
              onDismissed: (direction) {
                expenseDao.deleteTransaction(tx.id);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Transacción eliminada")));
              },
              child: _ExpenseHistoryItem(transaction: tx),
            );
          },
        );
      },
    );
  }
}

class _ExpenseHistoryItem extends StatelessWidget {
  final FinancialTransaction transaction;

  const _ExpenseHistoryItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 45, height: 45,
            decoration: BoxDecoration(
              color: Color(transaction.colorValue).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              IconData(transaction.categoryIconCode, fontFamily: 'FontAwesomeSolid', fontPackage: 'font_awesome_flutter'),
              color: Color(transaction.colorValue),
              size: 20,
            ),
          ),
          
          const Gap(12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.note,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('dd MMM yyyy - HH:mm', 'es').format(transaction.date),
                  style: TextStyle(fontSize: 10, color: colors.outline),
                ),
              ],
            ),
          ),

          Text(
            "- \$${transaction.amount.toStringAsFixed(2)}",
            style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.red, fontSize: 16),
          ),
        ],
      ),
    );
  }
}