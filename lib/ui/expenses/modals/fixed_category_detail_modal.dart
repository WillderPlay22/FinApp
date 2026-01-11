import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/category.dart';
import '../../../logic/providers/database_providers.dart';
import '../../../data/daos/expense_dao.dart';
import '../../../date_utils.dart';
import 'add_expense_modal.dart';
import '../../shared/icon_mapper.dart'; // ✅ Esta ruta ya es correcta
import 'create_category_modal.dart'; // Asumimos que este es tu modal para crear/editar categorías

// ✅ 1. Se crea un provider que "observa" la lista de gastos de una categoría específica.
// Cada vez que un gasto se añade, edita o borra, este provider lo notificará.
final categoryExpensesProvider = StreamProvider.family<List<Expense>, int>((ref, categoryId) {
  final expenseDao = ref.watch(expenseDaoProvider);
  return expenseDao.watchExpensesForCategory(categoryId);
});

class FixedCategoryDetailModal extends ConsumerWidget {
  // ✅ 2. El modal ahora solo necesita el ID de la categoría.
  // Obtendrá los datos de forma reactiva desde los providers.
  final int categoryId;

  const FixedCategoryDetailModal({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final expenseDao = ref.read(expenseDaoProvider);

    // ✅ 3. Observamos los dos streams de datos que necesitamos.
    // `ref.watch` reconstruirá este widget cuando cualquiera de los dos emita nuevos datos.
    final expensesAsyncValue = ref.watch(categoryExpensesProvider(categoryId));
    // Usamos el método `watchCategory` que añadiste a tu CategoryDao.
    final categoryStream = ref.watch(categoryDaoProvider).watchCategory(categoryId);

    return StreamBuilder<Category?>(
      stream: categoryStream,
      builder: (context, categorySnapshot) {
        // Mientras los datos cargan o si hay un error, mostramos un indicador.
        if (categorySnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final category = categorySnapshot.data;
        if (category == null) {
          // Si la categoría es null (se borró), mostramos un contenedor vacío mientras el modal se cierra manualmente.
          return const SizedBox.shrink();
        }

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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Row(
                  children: [
                    Icon(
                      getIconFromCode(category.iconCode),
                      color: Color(category.colorValue),
                      size: 30,
                    ),
                    const Gap(15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(category.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text(getFrequencyLabel(category.frequency), style: TextStyle(color: colors.outline, letterSpacing: 1.2)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_note_outlined),
                      tooltip: "Editar Categoría",
                      onPressed: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (context) => CreateCategoryModal(categoryToEdit: category),
                        );
                      },
                    ),
                    // ✅ BOTÓN DE BORRADO DE CATEGORÍA
                    IconButton(
                      icon: Icon(Icons.delete_forever_outlined, color: colors.error),
                      tooltip: "Eliminar Categoría",
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("¿Eliminar categoría?"),
                            content: Text(
                                "Se borrará la categoría '${category.name}', todos sus pagos asociados y su historial de transacciones.\n\nEsta acción no se puede deshacer."),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
                              TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text("Eliminar", style: TextStyle(color: colors.error))),
                            ],
                          ),
                        );

                        // Se comprueba que el widget sigue montado ANTES de la operación asíncrona.
                        if (confirm == true && context.mounted) {
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          
                          await ref.read(expenseDaoProvider).deleteCategoryAndRelatedData(categoryId);
                          
                          navigator.pop(); // Cerramos el modal explícitamente
                          messenger.showSnackBar(
                              const SnackBar(content: Text("Categoría eliminada con éxito.")));
                        }
                      },
                    ),
                  ],
                ),
              ),

              // LISTA DE ITEMS (HIJOS)
              Expanded(
                // Usamos .when para manejar los estados de carga/error del stream de gastos
                child: expensesAsyncValue.when(
                  data: (expenses) {
                    if (expenses.isEmpty) {
                      return const Center(child: Text("No hay pagos en esta categoría."));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: expenses.length,
                      separatorBuilder: (c, i) => const Gap(12),
                      itemBuilder: (context, index) {
                        final expense = expenses[index];
                        return _ExpenseChildItem(expense: expense, expenseDao: expenseDao);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text("Error: $err")),
                ),
              ),

              // BOTÓN AGREGAR ITEM A ESTA CATEGORÍA
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (ctx) => AddExpenseModal(preSelectedCategory: category),
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
      },
    );
  }
}

class _ExpenseChildItem extends StatelessWidget {
  final Expense expense;
  final ExpenseDao expenseDao;

  const _ExpenseChildItem({required this.expense, required this.expenseDao});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return StreamBuilder<CycleStatus>(
      stream: expenseDao.watchCycleStatus(expense),
      builder: (context, snapshot) {
        final status = snapshot.data ?? CycleStatus(totalSpent: 0, paymentCount: 0, isFullyPaid: false);
        final isPaid = status.isFullyPaid;

        return InkWell(
          onTap: () {
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
              color: colors.surfaceContainerHighest.withAlpha((255 * 0.3).round()),
              borderRadius: BorderRadius.circular(12),
              border: isPaid ? Border.all(color: Colors.red.shade300, width: 1.5) : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(expense.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, decoration: isPaid ? TextDecoration.lineThrough : null, color: isPaid ? Colors.grey : null)),
                      Text("\$${expense.amount.toStringAsFixed(2)}", style: TextStyle(color: isPaid ? Colors.red.shade300 : colors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (!isPaid)
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline, size: 28),
                    color: colors.outline,
                    onPressed: () => _confirmPayment(context, expenseDao, expense),
                  )
                else
                  Icon(Icons.check_circle, color: Colors.red.shade300, size: 28),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmPayment(BuildContext context, ExpenseDao dao, Expense expense) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("Pagar ${expense.title}"),
        content: Text("¿Confirmar pago de \$${expense.amount}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              await dao.markFixedExpenseAsPaid(expense);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text("Confirmar"),
          )
        ],
      ),
    );
  }
}