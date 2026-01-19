import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../data/models/expense.dart';
import '../../../logic/models/category_with_expenses.dart';
import '../../../logic/providers/database_providers.dart';
import '../../../data/daos/expense_dao.dart';
import 'add_expense_modal.dart'; // Para editar gastos individuales

class FixedCategoryDetailModal extends ConsumerWidget {
  final CategoryWithExpenses data;

  const FixedCategoryDetailModal({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final category = data.category;
    final expenseDao = ref.read(expenseDaoProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // HEADER CATEGORÍA
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: Color(category.colorValue).withOpacity(0.15),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Row(
              children: [
                Icon(
                  IconData(category.iconCode,
                      fontFamily: 'FontAwesomeSolid',
                      fontPackage: 'font_awesome_flutter'),
                  color: Color(category.colorValue),
                  size: 30,
                ),
                const Gap(15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.name,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(
                          "Gastos fijos ${_getFrequencyLabel(category.frequency)}",
                          style: TextStyle(color: colors.outline)),
                    ],
                  ),
                ),
                // BOTÓN EDITAR CATEGORÍA (Opcional)
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () {
                    // Aquí podrías abrir CreateCategoryModal en modo edición
                  },
                )
              ],
            ),
          ),

          // LISTA DE ITEMS (HIJOS)
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: data.expenses.length,
              separatorBuilder: (c, i) => const Gap(12),
              itemBuilder: (context, index) {
                final expense = data.expenses[index];
                return _ExpenseChildItem(
                    expense: expense, expenseDao: expenseDao);
              },
            ),
          ),

          // BOTÓN AGREGAR ITEM A ESTA CATEGORÍA
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Abrir modal de agregar gasto PRE-SELECCIONANDO esta categoría
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (ctx) =>
                        AddExpenseModal(preSelectedCategory: category),
                  );
                },
                icon: const Icon(Icons.add),
                label: Text("Agregar Item a ${category.name}"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFrequencyLabel(dynamic freq) =>
      freq.toString().split('.').last.toUpperCase();
}

class _ExpenseChildItem extends StatelessWidget {
  final Expense expense;
  final ExpenseDao expenseDao;

  const _ExpenseChildItem({required this.expense, required this.expenseDao});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Stream individual para ver si ESTE item específico ya se pagó
    return StreamBuilder<CycleStatus>(
      stream: expenseDao.watchCycleStatus(expense),
      builder: (context, snapshot) {
        final status = snapshot.data ??
            CycleStatus(totalSpent: 0, paymentCount: 0, isFullyPaid: false);
        final isPaid = status.isFullyPaid;

        return InkWell(
          onTap: () {
            // Editar el item individual
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (ctx) => AddExpenseModal(expenseToEdit: expense),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: colors.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border:
                  isPaid ? Border.all(color: Colors.green, width: 1.5) : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(expense.title,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              decoration:
                                  isPaid ? TextDecoration.lineThrough : null,
                              color: isPaid ? Colors.grey : colors.onSurface)),
                      Text("\$${expense.amount.toStringAsFixed(2)}",
                          style: TextStyle(
                              color: isPaid ? Colors.green : colors.primary,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                // BOTÓN DE PAGO RÁPIDO
                if (!isPaid)
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline, size: 28),
                    color: colors.outline,
                    onPressed: () =>
                        _confirmPayment(context, expenseDao, expense),
                  )
                else
                  const Icon(Icons.check_circle, color: Colors.green, size: 28),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmPayment(BuildContext context, ExpenseDao dao, Expense expense) {
    final controller =
        TextEditingController(text: expense.amount.toStringAsFixed(0));
    final category = expense.category.value;
    final categoryColor =
        category != null ? Color(category.colorValue) : Colors.grey;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Confirmar Pago: ${expense.title}",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            if (category != null) ...[
              const Gap(8),
              Text("Categoría: ${category.name}",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center),
            ],
            const Gap(20),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              autofocus: true,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: categoryColor),
              decoration: InputDecoration(
                  prefixIcon: Icon(Icons.attach_money, color: categoryColor),
                  border: const OutlineInputBorder(),
                  hintText: "Monto pagado"),
            ),
            const Gap(20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: categoryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.check_circle),
              label: const Text("Confirmar Pago"),
              onPressed: () async {
                final paidAmount = double.tryParse(controller.text) ?? 0.0;
                if (paidAmount > 0) {
                  await dao.markFixedExpenseAsPaid(expense,
                      amountOverride: paidAmount);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          "Pago de \$${paidAmount.toStringAsFixed(0)} confirmado"),
                      backgroundColor: categoryColor,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                }
              },
            ),
            const Gap(8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar"),
            ),
          ],
        ),
      ),
    );
  }
}
