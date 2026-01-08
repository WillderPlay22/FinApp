import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local_db/isar_db.dart';
import '../models/debt.dart';
import '../models/transaction.dart'; // To record payments
import '../models/enums.dart'; // For TransactionType
import '../../ui/expenses/modals/add_debt_modal.dart'; // For DebtFrequency
import '../../logic/providers/time_provider.dart'; // For ref.read(nowProvider)

class DebtDao {
  final IsarService isarService;
  final Ref ref;

  DebtDao(this.isarService, this.ref);

  // Save a new debt
  Future<void> saveDebt(Debt debt) async {
    final isar = await isarService.db;
    await isar.writeTxn(() async {
      await isar.debts.put(debt);
    });
  }

  // Watch all debts
  Stream<List<Debt>> watchAllDebts() async* {
    final isar = await isarService.db;
    yield* isar.debts.where().watch(fireImmediately: true);
  }

  // Mark an installment as paid
  Future<void> markInstallmentAsPaid(Debt debt) async {
    final isar = await isarService.db;
    final now = ref.read(nowProvider);

    // Create a transaction for the payment
    final transaction = FinancialTransaction()
      ..amount = debt.installmentAmount
      ..date = now
      ..note = "Pago de cuota: ${debt.title}"
      ..type = TransactionType.expense // Debt payments are expenses
      ..isRecurring = true // Could be considered recurring if part of a debt plan
      ..categoryName = "Deudas" // Default category for debt payments
      ..categoryIconCode = 0xf53d // FontAwesomeIcons.fileInvoiceDollar.codePoint
      ..colorValue = 0xFF9C27B0 // Purple color for debts
      ..relatedDebt.value = debt; // Link to the debt

    await isar.writeTxn(() async {
      await isar.financialTransactions.put(transaction);
      await transaction.relatedDebt.save();

      // Update debt's remaining amount and next payment date
      debt.remainingAmount -= debt.installmentAmount;
      if (debt.remainingAmount <= 0) {
        debt.isPaidOff = true;
        debt.nextPaymentDate = null; // No more payments
      } else {
        debt.nextPaymentDate = calculateNextPaymentDate(debt.nextPaymentDate ?? now, debt.frequency, debt.customDays);
      }
      await isar.debts.put(debt);
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
        // This is tricky, usually 1st and 15th or 15th and end of month.
        // For simplicity, let's assume 15 days for now.
        return currentPaymentDate.add(const Duration(days: 15));
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