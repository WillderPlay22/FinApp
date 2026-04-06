import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../../../data/models/recurring_movement.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/transaction.dart';
import '../../../data/daos/recurring_dao.dart';
import '../../../data/daos/transaction_dao.dart';
import '../../../date_utils.dart';
import '../../../logic/providers/database_providers.dart';
import '../../../logic/providers/currency_providers.dart';
import '../../../logic/providers/time_provider.dart';
import '../../../logic/services/notification_service.dart';
import '../../shared/icon_mapper.dart';
import '../../planning/planning_providers.dart';

class RecurringDetailModal extends ConsumerStatefulWidget {
  final RecurringMovement movement;

  const RecurringDetailModal({super.key, required this.movement});

  @override
  ConsumerState<RecurringDetailModal> createState() =>
      _RecurringDetailModalState();
}

class _RecurringDetailModalState extends ConsumerState<RecurringDetailModal> {
  void _refresh() {
    if (mounted) setState(() {});
  }

  final Map<Frequency, String> frequencyNames = {
    Frequency.daily: "Diario",
    Frequency.weekly: "Semanal",
    Frequency.biweekly: "Quincenal",
    Frequency.monthly: "Mensual",
    Frequency.yearly: "Anual",
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final recurringDao = ref.watch(recurringDaoProvider);
    final transactionDao = ref.watch(transactionDaoProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 48),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.teal.withAlpha((255 * 0.1).round()),
                      shape: BoxShape.circle),
                  child: const Icon(FontAwesomeIcons.fileContract,
                      size: 32, color: Colors.teal),
                ),
                IconButton(
                  onPressed: () => _showEditDialog(context),
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  tooltip: "Editar",
                ),
              ],
            ),
            const Gap(16),
            Text(frequencyNames[widget.movement.frequency] ?? "Recurrente",
                textAlign: TextAlign.center,
                style: textStyles.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(widget.movement.title,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.outline, fontSize: 14)),
            const Gap(24),
            const Divider(),
            const Gap(16),
            Row(
              children: [
                const Icon(FontAwesomeIcons.calendarCheck,
                    size: 16, color: Colors.teal),
                const Gap(8),
                const Text(
                  "PROXIMO PAGO",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                      letterSpacing: 1),
                ),
              ],
            ),
            const Gap(15),
            _buildNextPaymentControl(context, recurringDao, transactionDao),
            const Gap(30),
          ],
        ),
      ),
    );
  }

  Widget _buildNextPaymentControl(
      BuildContext context, RecurringDao recurringDao, TransactionDao transactionDao) {
    return StreamBuilder<NextPaymentInfo>(
      stream: recurringDao.watchNextPayment(widget.movement),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
              height: 50, child: Center(child: CircularProgressIndicator()));
        }
        final next = snapshot.data!;
        final dateLabel = DateFormat('d MMMM yyyy', 'es').format(next.expectedDate);
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.teal.withAlpha((255 * 0.08).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event, size: 18, color: Colors.teal),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      "${next.label} - $dateLabel",
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.teal),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(12),
            _PaymentButton(
              label: next.label,
              dateExpected: next.expectedDate,
              parentIncome: widget.movement,
              amountToPay: next.amount,
              dao: transactionDao,
              onPaymentSuccess: _refresh,
            ),
          ],
        );
      },
    );
  }

  // --- LÓGICA DE EDICIÓN Y ELIMINACIÓN ---

  void _showEditDialog(BuildContext parentContext) {
    final titleCtrl = TextEditingController(text: widget.movement.title);

    final currentAmounts = widget.movement.paymentAmounts ?? [];
    double val1 = currentAmounts.isNotEmpty ? currentAmounts[0] : 0.0;
    double val2 = (currentAmounts.length > 1) ? currentAmounts[1] : val1;

    final amount1Ctrl = TextEditingController(text: val1.toString());
    final amount2Ctrl = TextEditingController(text: val2.toString());

    final isBiweekly = widget.movement.frequency == Frequency.biweekly;
    final isWeekly = widget.movement.frequency == Frequency.weekly;
    final isMonthly = widget.movement.frequency == Frequency.monthly;

    int selectedDay = (widget.movement.paymentDays?.isNotEmpty == true)
        ? widget.movement.paymentDays![0]
        : 1;

    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (ctxEdit) => StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          title: const Text("Editar Ingreso"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                        labelText: "Nombre",
                        prefixIcon: Icon(Icons.label_outline))),
                const Gap(15),
                if (isBiweekly) ...[
                  TextField(
                      controller: amount1Ctrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: "Monto Día 15",
                          prefixIcon: Icon(Icons.attach_money))),
                  const Gap(10),
                  TextField(
                      controller: amount2Ctrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: "Monto Día Último",
                          prefixIcon: Icon(Icons.attach_money))),
                ] else
                  TextField(
                      controller: amount1Ctrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: "Monto",
                          prefixIcon: Icon(Icons.attach_money))),
                const Gap(15),
                if (isWeekly || isMonthly) ...[
                  DropdownButton<int>(
                    value: selectedDay,
                    items: List.generate(
                        isWeekly ? 7 : 31,
                        (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text(isWeekly
                                ? _getDayName(i + 1)
                                : "Día ${i + 1}"))),
                    onChanged: (v) => setStateDialog(() => selectedDay = v!),
                  )
                ],
                const Gap(25),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text("Eliminar Ingreso",
                        style: TextStyle(color: Colors.red)),
                    onPressed: () async {
                      Navigator.of(ctxEdit).pop();
                      await Future.delayed(const Duration(milliseconds: 200));
                      if (mounted) {
                        _confirmDelete();
                      }
                    },
                  ),
                )
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctxEdit),
                child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () async {
                final newTitle = titleCtrl.text;
                final amt1 = double.tryParse(amount1Ctrl.text) ?? 0.0;
                final amt2 = double.tryParse(amount2Ctrl.text) ?? 0.0;

                Navigator.pop(ctxEdit);

                widget.movement.title = newTitle;
                if (isBiweekly) {
                  widget.movement.paymentAmounts = [amt1, amt2];
                } else {
                  widget.movement.paymentAmounts = [amt1];
                }
                if (isWeekly || isMonthly) {
                  widget.movement.paymentDays = [selectedDay];
                }

                await ref
                    .read(recurringDaoProvider)
                    .addRecurringMovement(widget.movement);
                final allIncomes = await ref
                    .read(recurringDaoProvider)
                    .getAllRecurringMovements();
                await NotificationService()
                    .scheduleAllNotifications(allIncomes);

                if (mounted) {
                  _refresh();
                }
              },
              child: const Text("Guardar"),
            )
          ],
        );
      }),
    );
  }

  void _confirmDelete() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctxConfirm) => AlertDialog(
              title: const Text("¿Eliminar?"),
              content: const Text("Se borrará este ingreso recurrente."),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctxConfirm),
                    child: const Text("Cancelar")),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white),
                    onPressed: () async {
                      Navigator.of(ctxConfirm).pop();

                      await ref
                          .read(recurringDaoProvider)
                          .deleteRecurringMovement(widget.movement.id);
                      final allIncomes = await ref
                          .read(recurringDaoProvider)
                          .getAllRecurringMovements();
                      await NotificationService()
                          .scheduleAllNotifications(allIncomes);

                      if (mounted) {
                        await Future.delayed(const Duration(milliseconds: 100));
                        if (mounted) {
                          Navigator.of(context).pop();
                        }
                      }
                    },
                    child: const Text("Eliminar"))
              ],
            ));
  }

  String _getDayName(int day) {
    const days = [
      "Lunes",
      "Martes",
      "Miércoles",
      "Jueves",
      "Viernes",
      "Sábado",
      "Domingo"
    ];
    if (day >= 1 && day <= 7) return days[day - 1];
    return "Día $day";
  }
}

class _PaymentButton extends ConsumerStatefulWidget {
  final String label;
  final DateTime dateExpected;
  final RecurringMovement parentIncome;
  final double amountToPay;
  final TransactionDao dao;
  final VoidCallback onPaymentSuccess;

  const _PaymentButton({
    required this.label,
    required this.dateExpected,
    required this.parentIncome,
    required this.amountToPay,
    required this.dao,
    required this.onPaymentSuccess,
  });

  @override
  ConsumerState<_PaymentButton> createState() => _PaymentButtonState();
}

class _PaymentButtonState extends ConsumerState<_PaymentButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 2),
        icon: const Icon(FontAwesomeIcons.handHoldingDollar, size: 18),
        label: Text("Cobrar \$${widget.amountToPay.toStringAsFixed(0)}"),
        onPressed: () => _showConfirmDialog(context),
      ),
    );
  }

  void _showConfirmDialog(BuildContext context) {
    final controller =
        TextEditingController(text: widget.amountToPay.toString());
    final usdController = TextEditingController();
    final bsController = TextEditingController();

    final isMulti = ref.read(isMultiCurrencyEnabledProvider);
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
                const Text("Confirmar Ingreso",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const Gap(20),
                if (!isMulti || selectedMode == PaymentMode.singleCurrency)
                  TextField(
                    controller: controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    autofocus: false,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.attach_money, color: Colors.green),
                        border: OutlineInputBorder()),
                  ),
                if (isMulti) ...[
                  const Gap(16),
                  Row(
                    children: [
                      _buildModeChip("USD", PaymentMode.allReference,
                          selectedMode, Colors.teal, (mode) {
                        setModalState(() => selectedMode = mode);
                      }),
                      const Gap(8),
                      _buildModeChip("USD + BS", PaymentMode.mixed,
                          selectedMode, Colors.teal, (mode) {
                        setModalState(() => selectedMode = mode);
                      }),
                      const Gap(8),
                      _buildModeChip("BS", PaymentMode.allLocal,
                          selectedMode, Colors.teal, (mode) {
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
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
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
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
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
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
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
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                      decoration: const InputDecoration(
                        prefixText: "Bs ",
                        border: OutlineInputBorder(),
                        hintText: "Parte en BS",
                      ),
                    ),
                  ],
                ],
                const Gap(20),
                ElevatedButton(
                  onPressed: () async {
                    double? currentRate;
                    String? currencyCode;
                    if (isMulti) {
                      final rateData = await ref.read(currentExchangeRateProvider.future);
                      currentRate = rateData?.rate;
                      currencyCode = widget.parentIncome.currencyCode;
                    }

                    // Fecha real del cobro (hoy), no la fecha esperada
                    final actualPayDate = ref.read(nowProvider);

                    // Capturar rangos ANTES de crear la transaccion
                    List<DateRange> rangesBeforePayment = [];
                    try {
                      rangesBeforePayment = await ref.read(dynamicPeriodRangesProvider.future);
                    } catch (_) {}

                    if (isMulti && selectedMode != PaymentMode.singleCurrency) {
                      final usdAmount = double.tryParse(usdController.text) ?? 0.0;
                      final bsAmount = double.tryParse(bsController.text) ?? 0.0;

                      double amount;
                      if (selectedMode == PaymentMode.allReference) {
                        amount = usdAmount;
                      } else if (selectedMode == PaymentMode.allLocal) {
                        amount = bsAmount;
                      } else {
                        amount = currentRate != null && currentRate > 0
                            ? usdAmount + (bsAmount / currentRate)
                            : usdAmount;
                      }

                      if (amount > 0) {
                        final newTx = FinancialTransaction()
                          ..amount = amount
                          ..note = "Cobro: ${widget.label}"
                          ..date = actualPayDate
                          ..type = TransactionType.income
                          ..isRecurring = true
                          ..categoryName = widget.parentIncome.title
                          ..categoryIconCode = FontAwesomeIcons.moneyBillWave.codePoint
                          ..colorValue = 0xFF4CAF50
                          ..parentRecurringId = widget.parentIncome.id;

                        await widget.dao.addTransaction(
                          newTx,
                          currencyCode: currencyCode,
                          exchangeRate: currentRate,
                          paymentMode: selectedMode,
                          fixedReferencePortion: usdAmount > 0 ? usdAmount : null,
                          fixedLocalPortion: bsAmount > 0 ? bsAmount : null,
                        );
                      }
                    } else {
                      final amount = double.tryParse(controller.text) ?? 0.0;
                      if (amount > 0) {
                        final newTx = FinancialTransaction()
                          ..amount = amount
                          ..note = "Cobro: ${widget.label}"
                          ..date = actualPayDate
                          ..type = TransactionType.income
                          ..isRecurring = true
                          ..categoryName = widget.parentIncome.title
                          ..categoryIconCode = FontAwesomeIcons.moneyBillWave.codePoint
                          ..colorValue = 0xFF4CAF50
                          ..parentRecurringId = widget.parentIncome.id;

                        await widget.dao.addTransaction(
                          newTx,
                          currencyCode: currencyCode,
                          exchangeRate: currentRate,
                        );
                      }
                    }

                    if (context.mounted) {
                      Navigator.pop(ctx);
                      widget.onPaymentSuccess();
                      // Flujo de transición de periodo (con rangos pre-pago)
                      if (context.mounted) {
                        await _runPeriodTransitionFlow(context, actualPayDate, rangesBeforePayment);
                      }
                    }
                  },
                  child: const Text("Confirmar"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Calcula los rangos de transición: periodo anterior y nuevo inicio.
  Future<({DateRange previousPeriod, DateTime newPeriodStart})> _getTransitionRanges(
    DateTime newPaymentDate, int parentRecurringId, Isar isar,
  ) async {
    // Buscar último ingreso confirmado del mismo recurring ANTES de esta fecha
    final lastIncome = await isar.financialTransactions
        .filter()
        .parentRecurringIdEqualTo(parentRecurringId)
        .typeEqualTo(TransactionType.income)
        .dateLessThan(newPaymentDate)
        .sortByDateDesc()
        .findFirst();

    final prevStart = lastIncome?.date ?? DateTime(newPaymentDate.year, newPaymentDate.month, 1);
    final prevEnd = newPaymentDate.subtract(const Duration(days: 1));

    return (
      previousPeriod: DateRange(
        DateTime(prevStart.year, prevStart.month, prevStart.day),
        DateTime(prevEnd.year, prevEnd.month, prevEnd.day, 23, 59, 59),
      ),
      newPeriodStart: newPaymentDate,
    );
  }

  /// Ejecuta el flujo completo de transición de periodo después de confirmar ingreso.
  /// [rangesBeforePayment] son los rangos dinámicos capturados ANTES de crear la transacción,
  /// necesarios para mapear correctamente los indices de columna de los bloques asignados.
  Future<void> _runPeriodTransitionFlow(
    BuildContext parentContext, DateTime actualPayDate, List<DateRange> rangesBeforePayment,
  ) async {
    final expenseDao = ref.read(expenseDaoProvider);
    final isar = await expenseDao.isarService.db;

    // 1. Obtener rangos de transición (usando fecha real del cobro)
    final ranges = await _getTransitionRanges(
      actualPayDate, widget.parentIncome.id, isar,
    );

    // 2. Checklist de gastos del periodo ANTERIOR (usando rangos pre-pago)
    final checklistResult = await _showExpenseChecklist(
      parentContext, ranges.previousPeriod, actualPayDate, rangesBeforePayment,
    );
    if (checklistResult == null || !parentContext.mounted) return;

    // 3. Disposición de gastos no marcados
    if (checklistResult.uncheckedItems.isNotEmpty && parentContext.mounted) {
      await _showExpenseDisposition(parentContext, checklistResult.uncheckedItems);
    }

    // 4. Remanente del periodo anterior
    if (parentContext.mounted) {
      await _showRemainingDialog(parentContext, ranges.previousPeriod, ranges.newPeriodStart);
    }

    // 5. Invalidar providers de planificación para que se recalculen los rangos
    ref.invalidate(dynamicPeriodRangesProvider);
    ref.invalidate(monthRealTransactionsProvider);
  }

  /// Muestra un checklist de gastos fijos no pagados.
  /// Mid-month: solo gastos planificados para la columna del periodo anterior.
  /// End-of-month: todos los gastos con pagos pendientes del mes + no planificados.
  /// [rangesBeforePayment] son los rangos capturados ANTES de crear la transacción de ingreso.
  Future<_ChecklistResult?> _showExpenseChecklist(
    BuildContext parentContext, DateRange previousPeriod, DateTime actualPayDate,
    List<DateRange> rangesBeforePayment,
  ) async {
    final expenseDao = ref.read(expenseDaoProvider);
    final isar = await expenseDao.isarService.db;
    final positions = ref.read(planningPositionsProvider);

    final allFixed = await isar.expenses.filter().isRecurringEqualTo(true).findAll();
    if (allFixed.isEmpty) return _ChecklistResult(checkedItems: [], uncheckedItems: []);

    // Determinar si es transición de mes o mid-month
    final isNewMonth = previousPeriod.start.month != actualPayDate.month ||
        previousPeriod.start.year != actualPayDate.year;

    // Para mid-month: determinar columna anterior usando rangos PRE-PAGO
    // (los rangos actuales ya se recalcularon con la nueva transacción y los indices cambiaron)
    int? previousColumn;
    if (!isNewMonth) {
      for (int i = 0; i < rangesBeforePayment.length; i++) {
        if (!previousPeriod.end.isBefore(rangesBeforePayment[i].start) &&
            !previousPeriod.end.isAfter(rangesBeforePayment[i].end)) {
          previousColumn = i;
          break;
        }
      }
      // Fallback si no se encontró en ningún rango
      previousColumn ??= 0;
    }

    // Rango mensual para contar pagos del mes del periodo anterior
    final prevMonthYear = previousPeriod.start.year;
    final prevMonth = previousPeriod.start.month;
    final monthStart = DateTime(prevMonthYear, prevMonth, 1);
    final monthEnd = DateTime(prevMonthYear, prevMonth + 1, 0, 23, 59, 59);

    final List<_ChecklistItem> unpaidItems = [];

    for (var expense in allFixed) {
      await expense.category.load();
      final cat = expense.category.value;
      if (cat == null) continue;

      int blocksCount = 1;
      if (expense.frequency == Frequency.biweekly) blocksCount = 2;
      if (expense.frequency == Frequency.weekly) blocksCount = 4;

      // Contar pagos confirmados en el mes
      final paidInMonth = await isar.financialTransactions
          .filter()
          .relatedExpense((q) => q.idEqualTo(expense.id))
          .dateBetween(monthStart, monthEnd)
          .count();

      if (isNewMonth) {
        // Fin de mes: preguntar por TODOS los bloques con pagos pendientes
        for (int i = paidInMonth; i < blocksCount; i++) {
          unpaidItems.add(_ChecklistItem(
            expense: expense,
            categoryName: cat.name,
            iconCode: cat.iconCode,
            colorValue: cat.colorValue,
            blockIndex: i,
            partLabel: blocksCount > 1 ? 'Parte ${i + 1} de $blocksCount' : null,
          ));
        }
      } else {
        // Mid-month: solo preguntar por bloques asignados a la columna anterior
        if (previousColumn == null) continue;

        for (int i = 0; i < blocksCount; i++) {
          final blockId = "exp_${expense.id}_$i";
          final assignedColumn = positions[blockId];

          // El bloque está asignado a la columna del periodo que termina y no está pagado
          if (assignedColumn == previousColumn && i >= paidInMonth) {
            unpaidItems.add(_ChecklistItem(
              expense: expense,
              categoryName: cat.name,
              iconCode: cat.iconCode,
              colorValue: cat.colorValue,
              blockIndex: i,
              partLabel: blocksCount > 1 ? 'Parte ${i + 1} de $blocksCount' : null,
            ));
          }
        }
      }
    }

    if (unpaidItems.isEmpty || !parentContext.mounted) {
      return _ChecklistResult(checkedItems: [], uncheckedItems: []);
    }

    final isMulti = ref.read(isMultiCurrencyEnabledProvider);

    if (!parentContext.mounted) return null;

    final result = await showModalBottomSheet<_ChecklistResult>(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ExpenseChecklistSheet(
        items: unpaidItems,
        isMultiCurrency: isMulti,
        expenseDao: expenseDao,
        ref: ref,
        consolidationDate: previousPeriod.end,
      ),
    );

    return result ?? _ChecklistResult(checkedItems: [], uncheckedItems: unpaidItems);
  }

  /// Muestra un dialog para disponer de gastos no marcados (mover al nuevo periodo u omitir).
  Future<void> _showExpenseDisposition(
    BuildContext parentContext, List<_ChecklistItem> uncheckedItems,
  ) async {
    if (!parentContext.mounted) return;

    await showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ExpenseDispositionSheet(
        items: uncheckedItems,
        ref: ref,
      ),
    );
  }

  /// Muestra dialog para confirmar el remanente del periodo anterior.
  Future<void> _showRemainingDialog(
    BuildContext parentContext, DateRange previousPeriod, DateTime newPeriodStart,
  ) async {
    if (!parentContext.mounted) return;

    final isar = await ref.read(expenseDaoProvider).isarService.db;
    final isMulti = ref.read(isMultiCurrencyEnabledProvider);
    final transactionDao = ref.read(transactionDaoProvider);

    double? currentRate;
    if (isMulti) {
      final rateData = await ref.read(currentExchangeRateProvider.future);
      currentRate = rateData?.rate;
    }

    // Calcular remanente por defecto
    final prevTransactions = await isar.financialTransactions
        .filter()
        .dateBetween(previousPeriod.start, previousPeriod.end)
        .findAll();

    final prevIncome = prevTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.referenceAmountWithRate(currentRate));
    final prevExpenses = prevTransactions
        .where((t) => t.type == TransactionType.expense || t.type == TransactionType.saving)
        .fold(0.0, (sum, t) => sum + t.referenceAmountWithRate(currentRate));

    final defaultRemaining = (prevIncome - prevExpenses).clamp(0.0, double.infinity);

    if (!parentContext.mounted) return;

    await showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RemainingSheet(
        defaultRemaining: defaultRemaining,
        isMultiCurrency: isMulti,
        currentRate: currentRate,
        newPeriodStart: newPeriodStart,
        transactionDao: transactionDao,
        ref: ref,
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

// --- MODELO Y WIDGET PARA CHECKLIST DE GASTOS ---

class _ChecklistItem {
  final Expense expense;
  final String categoryName;
  final int iconCode;
  final int colorValue;
  final int blockIndex;
  final String? partLabel;

  _ChecklistItem({
    required this.expense,
    required this.categoryName,
    required this.iconCode,
    required this.colorValue,
    this.blockIndex = 0,
    this.partLabel,
  });

  String get uniqueKey => '${expense.id}_$blockIndex';
}

class _ChecklistResult {
  final List<_ChecklistItem> checkedItems;
  final List<_ChecklistItem> uncheckedItems;

  _ChecklistResult({required this.checkedItems, required this.uncheckedItems});
}

class _ExpenseChecklistSheet extends StatefulWidget {
  final List<_ChecklistItem> items;
  final bool isMultiCurrency;
  final dynamic expenseDao;
  final WidgetRef ref;
  final DateTime? consolidationDate;

  const _ExpenseChecklistSheet({
    required this.items,
    required this.isMultiCurrency,
    required this.expenseDao,
    required this.ref,
    this.consolidationDate,
  });

  @override
  State<_ExpenseChecklistSheet> createState() => _ExpenseChecklistSheetState();
}

class _ExpenseChecklistSheetState extends State<_ExpenseChecklistSheet> {
  late Map<String, bool> _checked;
  late Map<String, TextEditingController> _amountControllers;
  late Map<String, PaymentMode> _paymentModes;
  late Map<String, TextEditingController> _usdCtrl;
  late Map<String, TextEditingController> _bsCtrl;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _checked = {for (var item in widget.items) item.uniqueKey: false};
    _amountControllers = {};
    _paymentModes = {};
    _usdCtrl = {};
    _bsCtrl = {};

    for (var item in widget.items) {
      final key = item.uniqueKey;
      final isBs = item.expense.currencyCode == 'BS';
      final amountStr = item.expense.amount.toStringAsFixed(0);

      // Default amount controller (used when multi-currency is off or singleCurrency mode)
      _amountControllers[key] = TextEditingController(text: amountStr);

      // Default payment mode based on expense currency
      _paymentModes[key] = isBs ? PaymentMode.allLocal : PaymentMode.allReference;

      // Per-item USD/BS controllers
      _usdCtrl[key] = TextEditingController(text: isBs ? '' : amountStr);
      _bsCtrl[key] = TextEditingController(text: isBs ? amountStr : '');
    }
  }

  @override
  void dispose() {
    for (var c in _amountControllers.values) c.dispose();
    for (var c in _usdCtrl.values) c.dispose();
    for (var c in _bsCtrl.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final checkedCount = _checked.values.where((v) => v).length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const Gap(12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(16),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.checklist, color: colors.primary, size: 24),
                const Gap(10),
                Expanded(
                  child: Text(
                    "Pagaste estos gastos?",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                Text(
                  "$checkedCount/${widget.items.length}",
                  style: TextStyle(
                    color: colors.outline,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Gap(8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Marca los gastos fijos que pagaste con este ingreso",
              style: TextStyle(color: colors.outline, fontSize: 13),
            ),
          ),
          const Gap(16),
          const Divider(height: 1),
          // Lista de gastos
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: widget.items.length,
              itemBuilder: (ctx, index) {
                final item = widget.items[index];
                final key = item.uniqueKey;
                final isChecked = _checked[key] ?? false;
                final blockColor = Color(item.colorValue);
                final icon = getIconFromCode(item.iconCode);
                final isBs = item.expense.currencyCode == 'BS';
                final currencyPrefix = isBs ? "Bs " : "\$ ";
                final mode = _paymentModes[key] ?? PaymentMode.singleCurrency;

                // Determine which controller to show based on multi-currency state
                final bool showModeSelector = widget.isMultiCurrency && isChecked;
                final bool showSplitFields = widget.isMultiCurrency && isChecked && mode != PaymentMode.singleCurrency;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: isChecked
                        ? colors.primaryContainer.withAlpha(40)
                        : colors.surfaceContainerHighest.withAlpha(80),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isChecked
                          ? colors.primary.withAlpha(100)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      setState(() {
                        _checked[key] = !isChecked;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Checkbox
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isChecked
                                      ? Colors.green
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isChecked
                                        ? Colors.green
                                        : colors.outlineVariant,
                                    width: 2,
                                  ),
                                ),
                                child: isChecked
                                    ? const Icon(Icons.check,
                                        size: 18, color: Colors.white)
                                    : null,
                              ),
                              const Gap(12),
                              // Icono de categoría
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: blockColor.withAlpha(30),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(icon,
                                    size: 16,
                                    color: blockColor),
                              ),
                              const Gap(10),
                              // Nombre
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.partLabel != null
                                          ? '${item.categoryName} - ${item.partLabel}'
                                          : item.categoryName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: colors.onSurface,
                                        decoration: isChecked
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    Text(
                                      item.expense.title,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colors.outline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Monto (single field when not multi-currency or not checked)
                              if (!showSplitFields)
                                SizedBox(
                                  width: 90,
                                  child: TextField(
                                    controller: _amountControllers[key]!,
                                    enabled: isChecked,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isChecked
                                          ? Colors.green
                                          : colors.outline,
                                    ),
                                    decoration: InputDecoration(
                                      prefixText: currencyPrefix,
                                      prefixStyle: TextStyle(
                                        color: isChecked
                                            ? Colors.green
                                            : colors.outline,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: isChecked
                                              ? Colors.green.withAlpha(100)
                                              : colors.outlineVariant,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Colors.green.withAlpha(100),
                                        ),
                                      ),
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: colors.outlineVariant.withAlpha(60),
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: isChecked
                                          ? Colors.green.withAlpha(10)
                                          : colors.surfaceContainerHighest
                                              .withAlpha(60),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          // Mode selector + split fields (only when multi-currency enabled and item checked)
                          if (showModeSelector) ...[
                            const Gap(8),
                            Row(
                              children: [
                                const Gap(40), // align with content (checkbox + gap)
                                _buildCompactModeChip("USD", PaymentMode.allReference, mode, colors, (m) {
                                  setState(() => _paymentModes[key] = m);
                                }),
                                const Gap(4),
                                _buildCompactModeChip("USD+BS", PaymentMode.mixed, mode, colors, (m) {
                                  setState(() => _paymentModes[key] = m);
                                }),
                                const Gap(4),
                                _buildCompactModeChip("BS", PaymentMode.allLocal, mode, colors, (m) {
                                  setState(() => _paymentModes[key] = m);
                                }),
                              ],
                            ),
                          ],
                          if (showSplitFields) ...[
                            const Gap(8),
                            Padding(
                              padding: const EdgeInsets.only(left: 40),
                              child: Row(
                                children: [
                                  if (mode == PaymentMode.allReference || mode == PaymentMode.mixed)
                                    Expanded(
                                      child: TextField(
                                        controller: _usdCtrl[key],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                        decoration: InputDecoration(
                                          prefixText: "\$ ",
                                          prefixStyle: TextStyle(
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.green.withAlpha(100)),
                                          ),
                                          filled: true,
                                          fillColor: Colors.green.withAlpha(10),
                                          hintText: "USD",
                                          hintStyle: TextStyle(fontSize: 12, color: colors.outline),
                                        ),
                                      ),
                                    ),
                                  if (mode == PaymentMode.mixed) const Gap(8),
                                  if (mode == PaymentMode.allLocal || mode == PaymentMode.mixed)
                                    Expanded(
                                      child: TextField(
                                        controller: _bsCtrl[key],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade700,
                                        ),
                                        decoration: InputDecoration(
                                          prefixText: "Bs ",
                                          prefixStyle: TextStyle(
                                            color: Colors.orange.shade700,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.orange.withAlpha(100)),
                                          ),
                                          filled: true,
                                          fillColor: Colors.orange.withAlpha(10),
                                          hintText: "BS",
                                          hintStyle: TextStyle(fontSize: 12, color: colors.outline),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Botones
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(
                      context,
                      _ChecklistResult(
                        checkedItems: [],
                        uncheckedItems: widget.items,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Omitir"),
                  ),
                ),
                const Gap(12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: checkedCount == 0 || _isSubmitting
                        ? null
                        : _confirmPayments,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle, size: 20),
                    label: Text(
                      _isSubmitting
                          ? "Guardando..."
                          : "Confirmar $checkedCount pago${checkedCount != 1 ? 's' : ''}",
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Future<void> _confirmPayments() async {
    setState(() => _isSubmitting = true);

    double? currentRate;
    if (widget.isMultiCurrency) {
      final rateData =
          await widget.ref.read(currentExchangeRateProvider.future);
      currentRate = rateData?.rate;
    }

    final List<_ChecklistItem> checked = [];
    final List<_ChecklistItem> unchecked = [];

    for (var item in widget.items) {
      final key = item.uniqueKey;
      if (_checked[key] != true) {
        unchecked.add(item);
        continue;
      }
      checked.add(item);

      final mode = _paymentModes[key] ?? PaymentMode.singleCurrency;

      if (widget.isMultiCurrency && mode != PaymentMode.singleCurrency) {
        final usd = double.tryParse(_usdCtrl[key]?.text ?? '') ?? 0.0;
        final bs = double.tryParse(_bsCtrl[key]?.text ?? '') ?? 0.0;

        double paidAmount;
        if (mode == PaymentMode.allReference) {
          paidAmount = usd;
        } else if (mode == PaymentMode.allLocal) {
          paidAmount = bs;
        } else {
          paidAmount = currentRate != null && currentRate > 0
              ? usd + (bs / currentRate)
              : usd;
        }

        await widget.expenseDao.markFixedExpenseAsPaid(
          item.expense,
          amountOverride: paidAmount,
          exchangeRate: currentRate,
          currencyCode: item.expense.currencyCode,
          paymentMode: mode,
          fixedReferencePortion: usd > 0 ? usd : null,
          fixedLocalPortion: bs > 0 ? bs : null,
          dateOverride: widget.consolidationDate,
        );
      } else {
        final amountText = _amountControllers[key]?.text ?? "";
        final paidAmount = double.tryParse(amountText) ?? item.expense.amount;

        await widget.expenseDao.markFixedExpenseAsPaid(
          item.expense,
          amountOverride: paidAmount,
          exchangeRate: currentRate,
          currencyCode: item.expense.currencyCode,
          dateOverride: widget.consolidationDate,
        );
      }
    }

    if (mounted) {
      Navigator.pop(
        context,
        _ChecklistResult(checkedItems: checked, uncheckedItems: unchecked),
      );
    }
  }

  Widget _buildCompactModeChip(String label, PaymentMode mode,
      PaymentMode current, ColorScheme colors, Function(PaymentMode) onTap) {
    final isSelected = current == mode;
    return GestureDetector(
      onTap: () => onTap(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? colors.primary : colors.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? colors.onPrimary : colors.outline,
          ),
        ),
      ),
    );
  }
}

// --- DISPOSITION SHEET (Gastos no pagados del periodo anterior) ---

class _ExpenseDispositionSheet extends StatefulWidget {
  final List<_ChecklistItem> items;
  final WidgetRef ref;

  const _ExpenseDispositionSheet({required this.items, required this.ref});

  @override
  State<_ExpenseDispositionSheet> createState() => _ExpenseDispositionSheetState();
}

class _ExpenseDispositionSheetState extends State<_ExpenseDispositionSheet> {
  // true = mover al nuevo periodo, false = omitir
  late Map<String, bool> _moveToNew;

  @override
  void initState() {
    super.initState();
    _moveToNew = {for (var item in widget.items) item.uniqueKey: true};
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Gap(12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: colors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.swap_horiz, color: colors.tertiary, size: 24),
                const Gap(10),
                Expanded(
                  child: Text(
                    "Gastos no pagados",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Estos gastos no se pagaron en el periodo anterior. ¿Quieres moverlos al nuevo periodo?",
              style: TextStyle(color: colors.outline, fontSize: 13),
            ),
          ),
          const Gap(16),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: widget.items.length,
              itemBuilder: (ctx, index) {
                final item = widget.items[index];
                final key = item.uniqueKey;
                final moveIt = _moveToNew[key] ?? true;
                final blockColor = Color(item.colorValue);
                final icon = getIconFromCode(item.iconCode);
                final isBs = item.expense.currencyCode == 'BS';

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withAlpha(80),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: blockColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, size: 16, color: blockColor),
                      ),
                      const Gap(10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.partLabel != null
                                  ? '${item.categoryName} - ${item.partLabel}'
                                  : item.categoryName,
                              style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: colors.onSurface)),
                            Text(
                              "${isBs ? 'Bs' : '\$'}${item.expense.amount.toStringAsFixed(0)}",
                              style: TextStyle(fontSize: 12, color: colors.outline),
                            ),
                          ],
                        ),
                      ),
                      // Toggle: Mover / Omitir
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: true, label: Text("Mover", style: TextStyle(fontSize: 11))),
                          ButtonSegment(value: false, label: Text("Omitir", style: TextStyle(fontSize: 11))),
                        ],
                        selected: {moveIt},
                        onSelectionChanged: (sel) {
                          setState(() => _moveToNew[key] = sel.first);
                        },
                        style: ButtonStyle(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final positionsCtrl = widget.ref.read(planningPositionsProvider.notifier);
                  // For items being moved, we keep their position (they stay assigned)
                  // For items being omitted, remove only the specific block from planning
                  for (var item in widget.items) {
                    final key = item.uniqueKey;
                    if (_moveToNew[key] != true) {
                      // Omitir: quitar solo este bloque especifico de planning
                      positionsCtrl.updatePosition("exp_${item.expense.id}_${item.blockIndex}", null);
                    }
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Confirmar"),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

// --- REMAINING SHEET (Remanente del periodo anterior) ---

class _RemainingSheet extends StatefulWidget {
  final double defaultRemaining;
  final bool isMultiCurrency;
  final double? currentRate;
  final DateTime newPeriodStart;
  final TransactionDao transactionDao;
  final WidgetRef ref;

  const _RemainingSheet({
    required this.defaultRemaining,
    required this.isMultiCurrency,
    required this.currentRate,
    required this.newPeriodStart,
    required this.transactionDao,
    required this.ref,
  });

  @override
  State<_RemainingSheet> createState() => _RemainingSheetState();
}

class _RemainingSheetState extends State<_RemainingSheet> {
  late TextEditingController _amountCtrl;
  late TextEditingController _usdCtrl;
  late TextEditingController _bsCtrl;
  PaymentMode _mode = PaymentMode.singleCurrency;
  bool _nothingLeft = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
        text: widget.defaultRemaining > 0 ? widget.defaultRemaining.toStringAsFixed(0) : "0");
    _usdCtrl = TextEditingController();
    _bsCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _usdCtrl.dispose();
    _bsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20, left: 20, right: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(16),
              Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: Colors.blue, size: 24),
                  const Gap(10),
                  Expanded(
                    child: Text(
                      "Remanente del Periodo Anterior",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(8),
              Text(
                "Según tus registros te quedaron:",
                style: TextStyle(color: colors.outline, fontSize: 13),
              ),
              const Gap(16),

              // Amount field (single mode or when multi-currency is off)
              if (!widget.isMultiCurrency || _mode == PaymentMode.singleCurrency)
                TextField(
                  controller: _amountCtrl,
                  enabled: !_nothingLeft,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _nothingLeft ? colors.outline : Colors.blue,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.attach_money,
                        color: _nothingLeft ? colors.outline : Colors.blue),
                    border: const OutlineInputBorder(),
                  ),
                ),

              // Mode selector
              if (widget.isMultiCurrency) ...[
                const Gap(16),
                Row(
                  children: [
                    _buildRemainingModeChip("USD", PaymentMode.allReference, colors),
                    const Gap(8),
                    _buildRemainingModeChip("USD + BS", PaymentMode.mixed, colors),
                    const Gap(8),
                    _buildRemainingModeChip("BS", PaymentMode.allLocal, colors),
                  ],
                ),
                const Gap(16),
                if (_mode == PaymentMode.allReference)
                  TextField(
                    controller: _usdCtrl,
                    enabled: !_nothingLeft,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold,
                      color: _nothingLeft ? colors.outline : Colors.green.shade700,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.attach_money,
                          color: _nothingLeft ? colors.outline : Colors.green.shade700),
                      border: const OutlineInputBorder(),
                      hintText: "Monto en USD",
                    ),
                  ),
                if (_mode == PaymentMode.allLocal)
                  TextField(
                    controller: _bsCtrl,
                    enabled: !_nothingLeft,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold,
                      color: _nothingLeft ? colors.outline : Colors.orange.shade700,
                    ),
                    decoration: InputDecoration(
                      prefixText: "Bs ",
                      border: const OutlineInputBorder(),
                      hintText: "Monto en BS",
                    ),
                  ),
                if (_mode == PaymentMode.mixed) ...[
                  TextField(
                    controller: _usdCtrl,
                    enabled: !_nothingLeft,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold,
                      color: _nothingLeft ? colors.outline : Colors.green.shade700,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.attach_money,
                          color: _nothingLeft ? colors.outline : Colors.green.shade700),
                      border: const OutlineInputBorder(),
                      hintText: "Parte en USD",
                    ),
                  ),
                  const Gap(12),
                  TextField(
                    controller: _bsCtrl,
                    enabled: !_nothingLeft,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold,
                      color: _nothingLeft ? colors.outline : Colors.orange.shade700,
                    ),
                    decoration: InputDecoration(
                      prefixText: "Bs ",
                      border: const OutlineInputBorder(),
                      hintText: "Parte en BS",
                    ),
                  ),
                ],
              ],
              const Gap(16),

              // "No me quedó nada" checkbox
              InkWell(
                onTap: () {
                  setState(() {
                    _nothingLeft = !_nothingLeft;
                    if (_nothingLeft) {
                      _amountCtrl.text = "0";
                      _usdCtrl.text = "";
                      _bsCtrl.text = "";
                    } else {
                      _amountCtrl.text = widget.defaultRemaining.toStringAsFixed(0);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _nothingLeft,
                        onChanged: (v) {
                          setState(() {
                            _nothingLeft = v ?? false;
                            if (_nothingLeft) {
                              _amountCtrl.text = "0";
                              _usdCtrl.text = "";
                              _bsCtrl.text = "";
                            } else {
                              _amountCtrl.text = widget.defaultRemaining.toStringAsFixed(0);
                            }
                          });
                        },
                      ),
                      Text("No me quedó nada",
                          style: TextStyle(color: colors.onSurface, fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const Gap(16),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _confirmRemaining,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("Confirmar"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemaining() async {
    setState(() => _isSubmitting = true);

    double usdAmount = 0;
    double bsAmount = 0;
    double totalAmount = 0;
    PaymentMode paymentMode = PaymentMode.singleCurrency;

    if (_nothingLeft) {
      // No remaining, skip creating transaction
      if (mounted) Navigator.pop(context);
      return;
    }

    if (widget.isMultiCurrency && _mode != PaymentMode.singleCurrency) {
      paymentMode = _mode;
      usdAmount = double.tryParse(_usdCtrl.text) ?? 0;
      bsAmount = double.tryParse(_bsCtrl.text) ?? 0;

      if (_mode == PaymentMode.allReference) {
        totalAmount = usdAmount;
      } else if (_mode == PaymentMode.allLocal) {
        totalAmount = bsAmount;
      } else {
        totalAmount = widget.currentRate != null && widget.currentRate! > 0
            ? usdAmount + (bsAmount / widget.currentRate!)
            : usdAmount;
      }
    } else {
      totalAmount = double.tryParse(_amountCtrl.text) ?? 0;
    }

    if (totalAmount <= 0) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final tx = FinancialTransaction()
      ..type = TransactionType.income
      ..note = "Remanente del periodo anterior"
      ..date = widget.newPeriodStart
      ..isRecurring = false
      ..categoryName = "Remanente"
      ..categoryIconCode = Icons.account_balance_wallet.codePoint
      ..colorValue = 0xFF2196F3
      ..amount = totalAmount;

    await widget.transactionDao.addTransaction(
      tx,
      currencyCode: widget.isMultiCurrency && _mode != PaymentMode.singleCurrency
          ? (_mode == PaymentMode.allLocal ? 'BS' : 'USD')
          : null,
      exchangeRate: widget.currentRate,
      paymentMode: paymentMode != PaymentMode.singleCurrency ? paymentMode : null,
      fixedReferencePortion: usdAmount > 0 ? usdAmount : null,
      fixedLocalPortion: bsAmount > 0 ? bsAmount : null,
    );

    if (mounted) Navigator.pop(context);
  }

  Widget _buildRemainingModeChip(String label, PaymentMode mode, ColorScheme colors) {
    final isSelected = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade400,
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
