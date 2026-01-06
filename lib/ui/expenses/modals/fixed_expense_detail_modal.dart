import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/transaction.dart';
import '../../../logic/providers/database_providers.dart';
import '../../../data/daos/expense_dao.dart'; // Importar CycleStatus
import 'add_expense_modal.dart';

class FixedExpenseDetailModal extends ConsumerWidget {
  final Expense expense;

  const FixedExpenseDetailModal({super.key, required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final expenseDao = ref.watch(expenseDaoProvider);

    return Container(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(color: colors.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 60, height: 5, decoration: BoxDecoration(color: colors.outlineVariant, borderRadius: BorderRadius.circular(10)))),
          const Gap(20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Color(expense.category.value?.colorValue ?? 0xFF9E9E9E).withOpacity(0.2), shape: BoxShape.circle),
                child: Icon(IconData(expense.category.value?.iconCode ?? 0xf128, fontFamily: 'FontAwesomeSolid', fontPackage: 'font_awesome_flutter'), color: Color(expense.category.value?.colorValue ?? 0xFF9E9E9E), size: 30),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(expense.category.value?.name ?? "Sin categoría", style: TextStyle(color: colors.outline)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                  showModalBottomSheet(context: context, isScrollControlled: true, builder: (context) => AddExpenseModal(expenseToEdit: expense));
                },
                icon: const Icon(Icons.edit_outlined),
              )
            ],
          ),

          const Gap(24),

          // ESTADO DETALLADO CON CycleStatus
          StreamBuilder<CycleStatus>(
            stream: expenseDao.watchCycleStatus(expense),
            builder: (context, snapshot) {
              final status = snapshot.data ?? CycleStatus(totalSpent: 0, paymentCount: 0, isFullyPaid: false);
              final isPaid = status.isFullyPaid;
              
              // ✅ MONTO A MOSTRAR (Real vs Proyectado)
              final displayAmount = isPaid ? status.totalSpent : expense.amount;

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isPaid ? Colors.green.withOpacity(0.1) : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isPaid ? Colors.green : colors.outlineVariant, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      isPaid ? "¡GASTO CUBIERTO!" : "PENDIENTE",
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: isPaid ? Colors.green : colors.primary, fontSize: 12),
                    ),
                    const Gap(10),
                    // ✅ AQUÍ SE MUESTRA EL CAMBIO
                    Text(
                      "\$${displayAmount.toStringAsFixed(2)}",
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: isPaid ? Colors.green : colors.onSurface),
                    ),
                    const Gap(20),
                    
                    if (!isPaid)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showPaymentDialog(context, ref, expense),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          icon: const Icon(Icons.check_circle),
                          label: const Text("PROCESAR PAGO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check_circle, color: Colors.green),
                          Gap(8),
                          Text("Ciclo completado", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),

          const Gap(24),
          const Text("Historial de Pagos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Gap(10),
          Expanded(
            child: StreamBuilder<List<FinancialTransaction>>(
              stream: expenseDao.watchHistoryForExpense(expense.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text("Sin pagos registrados", style: TextStyle(color: colors.outlineVariant)));
                final history = snapshot.data!;
                return ListView.separated(
                  itemCount: history.length,
                  separatorBuilder: (c, i) => const Divider(height: 20),
                  itemBuilder: (context, index) {
                    final tx = history[index];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(FontAwesomeIcons.calendarCheck, size: 16, color: colors.outline),
                            const Gap(10),
                            Text(DateFormat('dd MMM yyyy - HH:mm', 'es').format(tx.date), style: const TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                        Text("\$${tx.amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Diálogo de pago (Mismo que en la lista)
  void _showPaymentDialog(BuildContext context, WidgetRef ref, Expense expense) {
    final controller = TextEditingController(text: expense.amount.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Procesar ${expense.title}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Confirma el monto real pagado:"),
            const Gap(10),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(prefixText: "\$ ", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              final realAmount = double.tryParse(controller.text) ?? expense.amount;
              ref.read(expenseDaoProvider).markFixedExpenseAsPaid(expense, customAmount: realAmount);
              Navigator.pop(ctx);
              Navigator.pop(context); // Cerrar detalle
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gasto registrado: \$$realAmount")));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("Confirmar Pago"),
          ),
        ],
      ),
    );
  }
}