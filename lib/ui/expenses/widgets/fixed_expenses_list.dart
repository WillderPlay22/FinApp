import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/enums.dart'; 
import '../../../logic/providers/database_providers.dart';
// Importamos el DAO para tener acceso a la clase CycleStatus
import '../../../data/daos/expense_dao.dart';
import '../modals/fixed_expense_detail_modal.dart';

class FixedExpensesList extends ConsumerWidget {
  const FixedExpensesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseDao = ref.watch(expenseDaoProvider);
    final colors = Theme.of(context).colorScheme;

    return StreamBuilder<List<Expense>>(
      stream: expenseDao.watchFixedExpenses(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Error al cargar datos"));
        if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState(colors);

        final expenses = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: expenses.map((expense) {
              return _FixedExpenseItem(expense: expense);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FontAwesomeIcons.boxOpen, size: 50, color: colors.outlineVariant),
          const Gap(10),
          const Text("No hay gastos fijos configurados."),
        ],
      ),
    );
  }
}

class _FixedExpenseItem extends ConsumerWidget {
  final Expense expense;

  const _FixedExpenseItem({required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final expenseDao = ref.read(expenseDaoProvider);

    // ✅ USAMOS watchCycleStatus QUE TRAE EL MONTO REAL
    return StreamBuilder<CycleStatus>(
      stream: expenseDao.watchCycleStatus(expense),
      builder: (context, snapshot) {
        // Datos por defecto si no ha cargado
        final status = snapshot.data ?? CycleStatus(totalSpent: 0, paymentCount: 0, isFullyPaid: false);
        
        final isPaid = status.isFullyPaid;
        
        // ✅ LÓGICA DEL MONTO A MOSTRAR
        // Si ya está pagado (full), mostramos LO QUE SE GASTÓ REALMENTE.
        // Si está pendiente, mostramos LA PROYECCIÓN.
        final displayAmount = isPaid ? status.totalSpent : expense.amount;

        return GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true, 
              useSafeArea: true,
              backgroundColor: Colors.transparent,
              builder: (context) => FixedExpenseDetailModal(expense: expense),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: isPaid ? Border.all(color: Colors.green.withOpacity(0.5)) : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 45, height: 45,
                  decoration: BoxDecoration(
                    color: Color(expense.category.value?.colorValue ?? 0xFF9E9E9E).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    IconData(expense.category.value?.iconCode ?? 0xf128, fontFamily: 'FontAwesomeSolid', fontPackage: 'font_awesome_flutter'),
                    color: Color(expense.category.value?.colorValue ?? 0xFF9E9E9E),
                    size: 20,
                  ),
                ),
                const Gap(12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(expense.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Row(
                        children: [
                          Text(_getFrequencySimple(expense.frequency), style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant)),
                          if (isPaid) ...[
                            const Gap(8),
                            const Text("CUBIERTO", style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                          ] else if (status.paymentCount > 0) ...[
                             const Gap(8),
                             // Muestra progreso si es semanal/quincenal (Ej: 1/4)
                             Text("${status.paymentCount} Pagos", style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // ✅ AQUÍ SE MUESTRA EL MONTO REAL O EL PROYECTADO
                    Text(
                      "\$${displayAmount.toStringAsFixed(2)}", 
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.w900, 
                        color: isPaid ? Colors.green : colors.onSurface,
                        // Quitamos el tachado si quieres ver el monto real claro, o lo dejas.
                        // Yo lo quitaría para que se lea bien lo que pagaste.
                        decoration: null, 
                      )
                    ),
                    const Gap(4),
                    
                    GestureDetector(
                      onTap: isPaid 
                        ? null 
                        : () => _showPaymentDialog(context, ref, expense),
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          color: isPaid ? Colors.green : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: isPaid ? Colors.green : colors.outline, width: 2),
                        ),
                        child: isPaid 
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : const Icon(Icons.add, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gasto registrado: \$$realAmount")));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("Confirmar Pago"),
          ),
        ],
      ),
    );
  }

  String _getFrequencySimple(Frequency freq) {
    switch (freq) {
      case Frequency.weekly: return 'Semanal';
      case Frequency.biweekly: return 'Quincenal';
      case Frequency.monthly: return 'Mensual';
      case Frequency.yearly: return 'Anual';
      default: return 'Mensual';
    }
  }
}