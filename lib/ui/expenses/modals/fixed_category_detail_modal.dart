import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/category.dart';
import '../../../logic/providers/database_providers.dart';
import '../../../logic/providers/currency_providers.dart';
import '../../../data/daos/expense_dao.dart';
import '../../../date_utils.dart';
import 'add_expense_modal.dart';
import '../../shared/icon_mapper.dart';
import 'create_category_modal.dart';

// ✅ 1. Se crea un provider que "observa" la lista de gastos de una categoría específica.
// Cada vez que un gasto se añade, edita o borra, este provider lo notificará.
final categoryExpensesProvider =
    StreamProvider.family<List<Expense>, int>((ref, categoryId) {
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
    final categoryStream =
        ref.watch(categoryDaoProvider).watchCategory(categoryId);

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
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(30)),
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
                          Text(category.name,
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
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
                          builder: (context) =>
                              CreateCategoryModal(categoryToEdit: category),
                        );
                      },
                    ),
                    // ✅ BOTÓN DE BORRADO DE CATEGORÍA
                    IconButton(
                      icon: Icon(Icons.delete_forever_outlined,
                          color: colors.error),
                      tooltip: "Eliminar Categoría",
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("¿Eliminar categoría?"),
                            content: Text(
                                "Se borrará la categoría '${category.name}', todos sus pagos asociados y su historial de transacciones.\n\nEsta acción no se puede deshacer."),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text("Cancelar")),
                              TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text("Eliminar",
                                      style: TextStyle(color: colors.error))),
                            ],
                          ),
                        );

                        // Se comprueba que el widget sigue montado ANTES de la operación asíncrona.
                        if (confirm == true && context.mounted) {
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);

                          await ref
                              .read(expenseDaoProvider)
                              .deleteCategoryAndRelatedData(categoryId);

                          navigator.pop(); // Cerramos el modal explícitamente
                          messenger.showSnackBar(const SnackBar(
                              content: Text("Categoría eliminada con éxito.")));
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
                      return const Center(
                          child: Text("No hay pagos en esta categoría."));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: expenses.length,
                      separatorBuilder: (c, i) => const Gap(12),
                      itemBuilder: (context, index) {
                        final expense = expenses[index];
                        return _ExpenseChildItem(
                            expense: expense, expenseDao: expenseDao);
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
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
      },
    );
  }
}

class _ExpenseChildItem extends ConsumerWidget {
  final Expense expense;
  final ExpenseDao expenseDao;

  const _ExpenseChildItem({required this.expense, required this.expenseDao});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    return StreamBuilder<CycleStatus>(
      stream: expenseDao.watchCycleStatus(expense),
      builder: (context, snapshot) {
        final status = snapshot.data ??
            CycleStatus(totalSpent: 0, paymentCount: 0, isFullyPaid: false);
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
              color:
                  colors.surfaceContainerHighest.withAlpha((255 * 0.3).round()),
              borderRadius: BorderRadius.circular(12),
              border: isPaid
                  ? Border.all(color: Colors.red.shade300, width: 1.5)
                  : null,
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
                              color: isPaid ? Colors.grey : null)),
                      Row(
                        children: [
                          Text("\$${expense.amount.toStringAsFixed(2)}",
                              style: TextStyle(
                                  color:
                                      isPaid ? Colors.red.shade300 : colors.primary,
                                  fontWeight: FontWeight.bold)),
                          const Gap(8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.secondaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              getFrequencyLabel(expense.frequency),
                              style: TextStyle(fontSize: 9, color: colors.onSecondaryContainer, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isPaid)
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline, size: 28),
                    color: colors.outline,
                    onPressed: () =>
                        _confirmPayment(context, expenseDao, expense, ref),
                  )
                else
                  Icon(Icons.check_circle,
                      color: Colors.red.shade300, size: 28),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmPayment(BuildContext context, ExpenseDao dao, Expense expense, WidgetRef ref) {
    final category = expense.category.value;
    final categoryColor =
        category != null ? Color(category.colorValue) : Colors.grey;

    final isMulti = ref.read(isMultiCurrencyEnabledProvider);

    final controller =
        TextEditingController(text: expense.amount.toStringAsFixed(0));
    final usdController = TextEditingController();
    final bsController = TextEditingController();

    PaymentMode selectedMode = PaymentMode.singleCurrency;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20),
          child: SingleChildScrollView(
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
                // Campo de monto principal (modo single currency)
                if (!isMulti || selectedMode == PaymentMode.singleCurrency)
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
                // Selector de modo de pago (solo si multi-moneda activo)
                if (isMulti) ...[
                  const Gap(16),
                  Row(
                    children: [
                      _buildModeChip("USD", PaymentMode.allReference,
                          selectedMode, categoryColor, (mode) {
                        setModalState(() => selectedMode = mode);
                      }),
                      const Gap(8),
                      _buildModeChip("USD + BS", PaymentMode.mixed,
                          selectedMode, categoryColor, (mode) {
                        setModalState(() => selectedMode = mode);
                      }),
                      const Gap(8),
                      _buildModeChip("BS", PaymentMode.allLocal,
                          selectedMode, categoryColor, (mode) {
                        setModalState(() => selectedMode = mode);
                      }),
                    ],
                  ),
                  const Gap(16),
                  if (selectedMode == PaymentMode.allReference)
                    TextField(
                      controller: usdController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: categoryColor),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.attach_money, color: Colors.green),
                        border: OutlineInputBorder(),
                        hintText: "Monto en USD",
                      ),
                    ),
                  if (selectedMode == PaymentMode.allLocal)
                    TextField(
                      controller: bsController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: categoryColor),
                      decoration: const InputDecoration(
                        prefixText: "Bs ",
                        border: OutlineInputBorder(),
                        hintText: "Monto en BS",
                      ),
                    ),
                  if (selectedMode == PaymentMode.mixed) ...[
                    TextField(
                      controller: usdController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: categoryColor),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.attach_money, color: Colors.green),
                        border: OutlineInputBorder(),
                        hintText: "Parte en USD",
                      ),
                    ),
                    const Gap(12),
                    TextField(
                      controller: bsController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: categoryColor),
                      decoration: const InputDecoration(
                        prefixText: "Bs ",
                        border: OutlineInputBorder(),
                        hintText: "Parte en BS",
                      ),
                    ),
                  ],
                ],
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
                    double? currentRate;
                    String? currencyCode;
                    if (isMulti) {
                      final rateData = await ref.read(currentExchangeRateProvider.future);
                      currentRate = rateData?.rate;
                      currencyCode = expense.currencyCode;
                    }

                    if (isMulti && selectedMode != PaymentMode.singleCurrency) {
                      final usdAmount = double.tryParse(usdController.text) ?? 0.0;
                      final bsAmount = double.tryParse(bsController.text) ?? 0.0;

                      double paidAmount;
                      if (selectedMode == PaymentMode.allReference) {
                        paidAmount = usdAmount;
                      } else if (selectedMode == PaymentMode.allLocal) {
                        paidAmount = bsAmount;
                      } else {
                        paidAmount = currentRate != null && currentRate > 0
                            ? usdAmount + (bsAmount / currentRate)
                            : usdAmount;
                      }

                      if (paidAmount > 0) {
                        await dao.markFixedExpenseAsPaid(expense,
                            amountOverride: paidAmount,
                            exchangeRate: currentRate,
                            currencyCode: currencyCode,
                            paymentMode: selectedMode,
                            fixedReferencePortion: usdAmount > 0 ? usdAmount : null,
                            fixedLocalPortion: bsAmount > 0 ? bsAmount : null);
                      }
                    } else {
                      final paidAmount = double.tryParse(controller.text) ?? 0.0;
                      if (paidAmount > 0) {
                        PaymentMode? implicitMode;
                        if (isMulti && currencyCode != null) {
                          implicitMode = currencyCode == 'BS'
                              ? PaymentMode.allLocal
                              : PaymentMode.allReference;
                        }
                        await dao.markFixedExpenseAsPaid(expense,
                            amountOverride: paidAmount,
                            exchangeRate: currentRate,
                            currencyCode: currencyCode,
                            paymentMode: implicitMode,
                            fixedReferencePortion: implicitMode == PaymentMode.allReference ? paidAmount : null,
                            fixedLocalPortion: implicitMode == PaymentMode.allLocal ? paidAmount : null);
                      }
                    }

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text("Pago confirmado"),
                        backgroundColor: categoryColor,
                        behavior: SnackBarBehavior.floating,
                      ));
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
        ),
      ),
    );
  }

  Widget _buildModeChip(String label, PaymentMode mode, PaymentMode current,
      Color activeColor, Function(PaymentMode) onTap) {
    final isSelected = current == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: isSelected ? activeColor.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              // ignore: deprecated_member_use
              color: isSelected ? activeColor : Colors.grey.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? activeColor : Colors.grey,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
