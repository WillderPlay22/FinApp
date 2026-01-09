import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local_db/isar_db.dart';
import '../models/debt.dart';
import '../models/transaction.dart'; // To record payments
import '../models/enums.dart'; // For TransactionType
import '../../ui/expenses/modals/add_debt_modal.dart'; // For DebtFrequency
import '../../logic/providers/time_provider.dart'; // For ref.read(nowProvider)
import '../../date_utils.dart'; // For getCycleDateRange

class DebtDao {
  final IsarService isarService;
  final Ref ref;

  DebtDao(this.isarService, this.ref);

  // Save a new debt
  Future<void> saveDebt(Debt debt) async {
    final isar = await isarService.db;
    // Check if it's new before saving, as saving assigns an ID.
    final isNew = debt.id == Isar.autoIncrement;

    await isar.writeTxn(() async {
      await isar.debts.put(debt);

      // ✅ Si es una deuda nueva y tiene pago inicial, creamos la transacción automáticamente.
      if (isNew && debt.initialPayment > 0) {
        await _createDebtPaymentTransaction(
          isar,
          debt,
          debt.initialPayment,
          "Pago inicial: ${debt.title}",
        );
        // No necesitamos restar esto del remainingAmount porque AddDebtModal ya lo calculó (total - initial).
      }
    });
  }

  // Watch all debts
  Stream<List<Debt>> watchAllDebts() async* {
    final isar = await isarService.db;
    // ✅ Filter to show only debts that are NOT paid off
    yield* isar.debts.filter().isPaidOffEqualTo(false).watch(fireImmediately: true);
  }

  // Watch a specific debt by ID (active or paid)
  Stream<Debt?> watchDebt(int id) async* {
    final isar = await isarService.db;
    yield* isar.debts.watchObject(id, fireImmediately: true);
  }

  // Watch all transactions for a specific debt
  Stream<List<FinancialTransaction>> watchTransactionsForDebt(int debtId) async* {
    final isar = await isarService.db;
    yield* isar.financialTransactions
        .filter()
        .relatedDebt((q) => q.idEqualTo(debtId))
        .sortByDateDesc()
        .watch(fireImmediately: true);
  }

  // Mark an installment as paid
  // Returns true if the debt is fully paid off after this payment
  Future<bool> markInstallmentAsPaid(Debt debtParam) async {
    final isar = await isarService.db;
    final now = ref.read(nowProvider);
    bool isFullyPaid = false;

    await isar.writeTxn(() async {
      // 1. RECARGA OBLIGATORIA: Obtenemos la versión más reciente de la deuda desde la BD.
      final debt = await isar.debts.get(debtParam.id);
      if (debt == null) return;

      // Determina el monto real del pago.
      final paymentAmount = (debt.remainingAmount < debt.installmentAmount)
          ? debt.remainingAmount
          : debt.installmentAmount;

      if (paymentAmount <= 0) return;

      // Create a transaction for the payment
      final transaction = FinancialTransaction()
        ..amount = paymentAmount
        ..date = now
        ..note = "Pago de cuota: ${debt.title}"
        ..type = TransactionType.expense
        ..isRecurring = true
        ..categoryName = "Deudas"
        ..categoryIconCode = 0xf53d
        ..colorValue = 0xFF9C27B0
        ..relatedDebt.value = debt;

      await isar.financialTransactions.put(transaction);
      await transaction.relatedDebt.save();

      // Update debt's remaining amount and next payment date
      debt.remainingAmount -= paymentAmount;
      
      if (debt.remainingAmount < 0.01) {
        debt.remainingAmount = 0; // Asegurarse de que quede en 0
        debt.isPaidOff = true;
        debt.nextPaymentDate = null; // No more payments
        isFullyPaid = true;
      } else {
        // After a payment, we advance to the next cycle.
        debt.nextPaymentDate = calculateNextPaymentDate(debt.nextPaymentDate ?? now, debt.frequency, debt.customDays);

        // CORRECCIÓN DEFINITIVA: Solo restauramos si EXPLICITAMENTE tenemos un valor original guardado.
        // Eliminamos el fallback que recalculaba (total/count) porque eso destruía las amortizaciones
        // a todas las cuotas (que cambian el monto permanentemente).
        if (debt.originalInstallmentAmount != null) {
          debt.installmentAmount = debt.originalInstallmentAmount!;
        } else {
          // ✅ FALLBACK DE SEGURIDAD REINTRODUCIDO (CON CUIDADO):
          // Si 'originalInstallmentAmount' es null, significa que estamos en un estado inconsistente
          // (probablemente una deuda antigua o un error de guardado).
          // Calculamos el valor original matemáticamente para forzar la corrección (de 30 a 50).
          if (debt.installmentCount > 0) {
             final calculatedOriginal = (debt.totalAmount - debt.initialPayment) / debt.installmentCount;
             debt.installmentAmount = calculatedOriginal;
             // Guardamos este valor para arreglar el registro permanentemente.
             debt.originalInstallmentAmount = calculatedOriginal;
          }
        }
      }
      await isar.debts.put(debt);
    });

    return isFullyPaid;
  }

  // Delete a debt and all its related transactions
  Future<void> deleteDebtAndTransactions(int debtId) async {
    final isar = await isarService.db;
    await isar.writeTxn(() async {
      // Delete related transactions first
      await isar.financialTransactions.filter().relatedDebt((q) => q.idEqualTo(debtId)).deleteAll();
      // Then delete the debt itself
      await isar.debts.delete(debtId);
    });
  }

  // Generic method to create a payment transaction for a debt
  Future<void> _createDebtPaymentTransaction(Isar isar, Debt debt, double amount, String note) async {
    final now = ref.read(nowProvider);
    final transaction = FinancialTransaction()
      ..amount = amount
      ..date = now
      ..note = note
      ..type = TransactionType.expense
      ..isRecurring = true // Debt payments are part of a recurring plan
      ..categoryName = "Deudas"
      ..categoryIconCode = 0xf53d // FontAwesomeIcons.fileInvoiceDollar.codePoint
      ..colorValue = 0xFF9C27B0 // Purple
      ..relatedDebt.value = debt;

    await isar.financialTransactions.put(transaction);
    await transaction.relatedDebt.save();
  }

  // Amortize payment to principal, effectively paying off future installments sequentially.
  Future<void> amortizeToPrincipal(Debt debtParam, double amount) async {
    final isar = await isarService.db;
    await isar.writeTxn(() async {
      final debt = await isar.debts.get(debtParam.id);
      if (debt == null) return;

      // 1. Create the single transaction for the full amortization payment
      await _createDebtPaymentTransaction(isar, debt, amount, "Amortización a próximas cuotas: ${debt.title}");

      // 2. Reduce the total remaining amount of the debt
      debt.remainingAmount -= amount;
      if (debt.remainingAmount < 0.01) {
        debt.remainingAmount = 0;
        debt.isPaidOff = true;
        debt.nextPaymentDate = null;
        debt.installmentAmount = 0;
        await isar.debts.put(debt);
        return;
      }

      // 3. Loop to apply the payment to one or more installments
      double amountToApply = amount;

      // Backward compatibility: If original amount is not set, set it now.
      if (debt.originalInstallmentAmount == null) {
        if (debt.installmentCount > 0) {
           debt.originalInstallmentAmount = (debt.totalAmount - debt.initialPayment) / debt.installmentCount;
        } else {
           debt.originalInstallmentAmount = debt.installmentAmount;
        }
      }
      // We can now safely assume originalInstallmentAmount is not null.
      final baseInstallment = debt.originalInstallmentAmount!;

      while (amountToApply > 0 && !debt.isPaidOff) {
        double currentInstallmentDue = debt.installmentAmount;

        if (amountToApply >= currentInstallmentDue) {
          // This payment covers the current installment (or what's left of it) completely.
          amountToApply -= currentInstallmentDue;

          // Advance to the next payment cycle
          final now = ref.read(nowProvider);
          debt.nextPaymentDate = calculateNextPaymentDate(debt.nextPaymentDate ?? now, debt.frequency, debt.customDays);
          
          // Reset the installment amount for the new cycle to the original baseline
          debt.installmentAmount = baseInstallment;
        } else {
          // This payment only partially covers the current installment.
          debt.installmentAmount -= amountToApply;
          amountToApply = 0; // All the amount has been applied, exit loop
        }
      }

      // 4. Save the final state of the debt
      await isar.debts.put(debt);
    });
  }

  // Amortize payment to all remaining installments, reducing their individual amount
  Future<void> amortizeToInstallments(Debt debtParam, double amount) async {
    final isar = await isarService.db;
    await isar.writeTxn(() async {
      final debt = await isar.debts.get(debtParam.id);
      if (debt == null) return;

      await _createDebtPaymentTransaction(isar, debt, amount, "Amortización a todas las cuotas: ${debt.title}");

      // Calculate remaining installments BEFORE changing the remaining amount
      // Use the original amount for a stable calculation, robust against partial payments
      double baseInstallmentAmount = debt.originalInstallmentAmount ?? debt.installmentAmount;
      if (debt.originalInstallmentAmount == null && debt.installmentCount > 0) {
         baseInstallmentAmount = (debt.totalAmount - debt.initialPayment) / debt.installmentCount;
      }
      final remainingInstallments = baseInstallmentAmount > 0 ? (debt.remainingAmount / baseInstallmentAmount).ceil() : 0;

      debt.remainingAmount -= amount;

      if (debt.remainingAmount < 0.01) {
        debt.remainingAmount = 0;
        debt.isPaidOff = true;
        debt.nextPaymentDate = null;
        debt.installmentAmount = 0;
      } else if (remainingInstallments > 0) {
        // Recalculate the amount for the remaining installments
        debt.installmentAmount = debt.remainingAmount / remainingInstallments;
        // Also update the original amount, as this is the new baseline
        // CRITICAL FIX: This ensures markInstallmentAsPaid knows the new "normal" is the reduced amount.
        debt.originalInstallmentAmount = debt.installmentAmount;
      }

      await isar.debts.put(debt);
    });
  }

  // --- MÉTODOS PARA EL RESUMEN DE DEUDAS (HEADER) ---

  // Observa el total pagado en deudas este mes
  Stream<double> watchDebtPaidThisMonth(DateTime now) async* {
    final isar = await isarService.db;
    final range = getCycleDateRange(now, Frequency.monthly);

    yield* isar.financialTransactions
        .filter()
        .categoryNameEqualTo("Deudas")
        .dateBetween(range.start, range.end)
        .watch(fireImmediately: true)
        .map((txs) => txs.fold(0.0, (sum, t) => sum + t.amount));
  }

  // Observa el total pendiente de pago en deudas para este mes
  Stream<double> watchDebtPendingThisMonth(DateTime now) async* {
    final isar = await isarService.db;
    final range = getCycleDateRange(now, Frequency.monthly);

    yield* isar.debts.where().watch(fireImmediately: true).map((debts) {
      double totalPending = 0;
      for (final debt in debts) {
        if (debt.isPaidOff || debt.nextPaymentDate == null) continue;

        // Proyectar pagos dentro del mes actual
        DateTime date = debt.nextPaymentDate!;
        // Para la primera proyección usamos el monto actual (puede estar parcialmente pagado)
        double amountToAdd = debt.installmentAmount;
        // Para las siguientes proyecciones en el mismo mes, usamos el monto original
        double subsequentAmount = debt.originalInstallmentAmount ?? debt.installmentAmount;
        
        // Mientras la fecha de pago esté dentro del mes actual...
        while (date.isBefore(range.end) || date.isAtSameMomentAs(range.end)) {
          // Solo sumamos si la fecha es igual o posterior al inicio del rango (hoy/inicio mes)
          if (date.isAfter(range.start) || date.isAtSameMomentAs(range.start)) {
             totalPending += amountToAdd;
          }
          
          // Calcular la siguiente fecha para ver si cae también en este mes (ej: pagos semanales)
          date = calculateNextPaymentDate(date, debt.frequency, debt.customDays);
          amountToAdd = subsequentAmount; // Restablecemos al monto completo para siguientes ciclos
        }
      }
      return totalPending;
    });
  }

  // Helper to calculate next payment date
  DateTime calculateNextPaymentDate(DateTime currentPaymentDate, DebtFrequency frequency, int? customDays) {
    switch (frequency) {
      case DebtFrequency.daily:
        return currentPaymentDate.add(const Duration(days: 1));
      case DebtFrequency.weekly:
        return currentPaymentDate.add(const Duration(days: 7));
      case DebtFrequency.biweekly:
        return currentPaymentDate.add(const Duration(days: 14));
      case DebtFrequency.fortnightly:
        // Lógica mejorada para pagos quincenales (próximo 15 o fin de mes).
        final endOfMonth = DateTime(currentPaymentDate.year, currentPaymentDate.month + 1, 0);
        if (currentPaymentDate.day < 15) {
          // Si el pago fue antes del 15, el próximo es el 15 de este mes.
          return DateTime(currentPaymentDate.year, currentPaymentDate.month, 15);
        } else if (currentPaymentDate.day < endOfMonth.day) {
          // Si el pago fue el 15 o después (pero no fin de mes), el próximo es a fin de mes.
          return endOfMonth;
        } else { // Si el pago fue el último día del mes.
          return DateTime(currentPaymentDate.year, currentPaymentDate.month + 1, 15);
        }
      case DebtFrequency.monthly:
        return DateTime(currentPaymentDate.year, currentPaymentDate.month + 1, currentPaymentDate.day);
      case DebtFrequency.custom:
        return currentPaymentDate.add(Duration(days: customDays ?? 1));
    }
  }

  // Helper to calculate estimated due date
  DateTime calculateDueDate(DateTime creationDate, int installmentCount, DebtFrequency frequency, int? customDays) {
    DateTime dueDate = creationDate;
    for (int i = 0; i < installmentCount; i++) {
      dueDate = calculateNextPaymentDate(dueDate, frequency, customDays);
    }
    return dueDate;
  }
}