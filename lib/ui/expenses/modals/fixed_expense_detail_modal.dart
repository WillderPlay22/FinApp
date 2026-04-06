import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/enums.dart';
import '../../../logic/models/category_with_expenses.dart';
import '../../../logic/providers/database_providers.dart';
import '../../../logic/providers/currency_providers.dart';
import '../../../data/daos/expense_dao.dart';
import '../../shared/currency_amount_display.dart';
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
                          "Gastos fijos",
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
}

class _ExpenseChildItem extends ConsumerWidget {
  final Expense expense;
  final ExpenseDao expenseDao;

  const _ExpenseChildItem({required this.expense, required this.expenseDao});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final isMultiCurrency = ref.watch(isMultiCurrencyEnabledProvider);

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
                      if (isMultiCurrency)
                        CurrencyAmountDisplay(
                          amount: expense.amount,
                          currencyCode: expense.currencyCode,
                          primaryStyle: TextStyle(
                              color: isPaid ? Colors.green : colors.primary,
                              fontWeight: FontWeight.bold),
                          secondaryStyle: TextStyle(
                              color: isPaid ? Colors.green.withAlpha(150) : colors.outline,
                              fontSize: 11),
                        )
                      else
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
                        _confirmPayment(context, expenseDao, expense, widgetRef: ref),
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

  void _confirmPayment(BuildContext context, ExpenseDao dao, Expense expense, {WidgetRef? widgetRef}) {
    final category = expense.category.value;
    final categoryColor =
        category != null ? Color(category.colorValue) : Colors.grey;

    final isMulti = widgetRef?.read(isMultiCurrencyEnabledProvider) ?? false;

    // Controllers
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
                  // Campos según el modo seleccionado
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
                    if (widgetRef != null && isMulti) {
                      final rateData = await widgetRef.read(currentExchangeRateProvider.future);
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
                        // mixed: el monto principal es el equivalente en referencia
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
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? activeColor : Colors.grey.shade400,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}
