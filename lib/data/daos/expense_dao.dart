import 'package:isar/isar.dart';
import '../local_db/isar_db.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/enums.dart';

// Clase auxiliar para el estado del ciclo
class CycleStatus {
  final double totalSpent; 
  final int paymentCount;  
  final bool isFullyPaid;  

  CycleStatus({
    required this.totalSpent, 
    required this.paymentCount, 
    required this.isFullyPaid
  });
}

class ExpenseDao {
  final IsarService isarService;

  ExpenseDao(this.isarService);

  // 1. GUARDAR O EDITAR
  Future<void> saveExpense({
    int? id,
    required String title,
    required double amount,
    required DateTime date,
    required Category category,
    required bool isFixed,
    required Frequency frequency,
  }) async {
    final isar = await isarService.db;
    await isar.writeTxn(() async {
      if (isFixed) {
        final expense = Expense(
          title: title,
          amount: amount,
          date: date,
          isRecurring: true,
          frequency: frequency,
        );
        if (id != null) expense.id = id;
        await isar.expenses.put(expense);
        expense.category.value = category;
        await expense.category.save();
      } else {
        final transaction = FinancialTransaction()
          ..amount = amount
          ..note = title
          ..date = date
          ..type = TransactionType.expense
          ..categoryName = category.name
          ..categoryIconCode = category.iconCode
          ..colorValue = category.colorValue
          ..parentRecurringId = null;
        await isar.financialTransactions.put(transaction);
      }
    });
  }

  // 2. LEER GASTOS FIJOS
  Stream<List<Expense>> watchFixedExpenses() async* {
    final isar = await isarService.db;
    yield* isar.expenses.filter().isRecurringEqualTo(true).watch(fireImmediately: true);
  }

  // 3. PAGAR (Registra la transacción)
  Future<void> markFixedExpenseAsPaid(Expense expense, {double? customAmount}) async {
    final isar = await isarService.db;
    final now = DateTime.now();

    final newTx = FinancialTransaction()
      ..amount = customAmount ?? expense.amount
      ..note = expense.title 
      ..date = now 
      ..type = TransactionType.expense
      ..categoryName = expense.category.value?.name ?? 'Sin categoría'
      ..categoryIconCode = expense.category.value?.iconCode ?? 0
      ..colorValue = expense.category.value?.colorValue ?? 0xFF000000
      ..parentRecurringId = expense.id; 

    await isar.writeTxn(() async {
      await isar.financialTransactions.put(newTx);
    });
  }

  // ✅ 4. ESTADO DEL CICLO (Lógica Corregida)
  Stream<CycleStatus> watchCycleStatus(Expense expense) async* {
    final isar = await isarService.db;
    final now = DateTime.now();
    
    DateTime start, end;
    
    // ⚠️ CORRECCIÓN: El límite es SIEMPRE 1 pago por ciclo
    int maxPayments = 1; 

    // A. Definir el Rango de Fechas (La "Ventana" de Pago)
    switch (expense.frequency) {
      case Frequency.weekly:
        // De Lunes a Domingo de la semana ACTUAL
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day); // Inicio del día (00:00)
        end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59)); // Fin del domingo
        break;

      case Frequency.biweekly:
        // Quincenas estrictas: 1-15 o 16-Fin
        if (now.day <= 15) {
          start = DateTime(now.year, now.month, 1);
          end = DateTime(now.year, now.month, 15, 23, 59, 59);
        } else {
          start = DateTime(now.year, now.month, 16);
          end = DateTime(now.year, now.month + 1, 0, 23, 59, 59); // Día 0 del mes siguiente = último de este
        }
        break;

      case Frequency.monthly:
      case Frequency.yearly: // Tratamos anual como mensual por simplicidad visual
      default:
        // Todo el Mes Actual
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
    }

    // B. Contar pagos en esa ventana
    yield* isar.financialTransactions
        .filter()
        .parentRecurringIdEqualTo(expense.id)
        .and()
        .dateBetween(start, end)
        .watch(fireImmediately: true)
        .map((transactions) {
          double totalSpent = transactions.fold(0.0, (sum, t) => sum + t.amount);
          int count = transactions.length;
          
          return CycleStatus(
            totalSpent: totalSpent,
            paymentCount: count,
            // Si ya hay al menos 1 pago, está cubierto.
            isFullyPaid: count >= maxPayments 
          );
        });
  }

  // ... (Resto de métodos: watchTotalExecuted, watchTotalProjected, history, delete... igual que antes)
  // Te los incluyo resumidos para que el archivo esté completo si copias todo:

  Stream<double> watchTotalExecutedThisMonth() async* {
    final isar = await isarService.db;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    yield* isar.financialTransactions.filter().typeEqualTo(TransactionType.expense).dateBetween(start, end).watch(fireImmediately: true)
        .map((txs) => txs.fold(0.0, (sum, item) => sum + item.amount));
  }

  Stream<double> watchTotalProjectedThisMonth() async* {
    final isar = await isarService.db;
    final fixedStream = isar.expenses.filter().isRecurringEqualTo(true).watch(fireImmediately: true);
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    yield* fixedStream.asyncMap((fixedExpenses) async {
       double projectedFixed = 0.0;
       for (var e in fixedExpenses) {
         if (e.frequency == Frequency.weekly) projectedFixed += (e.amount * 4);
         else if (e.frequency == Frequency.biweekly) projectedFixed += (e.amount * 2);
         else projectedFixed += e.amount; 
       }
       final extras = await isar.financialTransactions.filter().typeEqualTo(TransactionType.expense).parentRecurringIdIsNull().dateBetween(start, end).findAll();
       double executedExtras = extras.fold(0.0, (sum, item) => sum + item.amount);
       return projectedFixed + executedExtras;
    });
  }

  Stream<List<FinancialTransaction>> watchExpenseHistory() async* {
    final isar = await isarService.db;
    yield* isar.financialTransactions.filter().typeEqualTo(TransactionType.expense).sortByDateDesc().watch(fireImmediately: true);
  }

  Stream<List<FinancialTransaction>> watchHistoryForExpense(int expenseId) async* {
    final isar = await isarService.db;
    yield* isar.financialTransactions.filter().parentRecurringIdEqualTo(expenseId).sortByDateDesc().watch(fireImmediately: true);
  }

  Future<void> deleteExpense(int id) async {
    final isar = await isarService.db;
    await isar.writeTxn(() async => await isar.expenses.delete(id));
  }

  Future<void> deleteTransaction(int id) async {
    final isar = await isarService.db;
    await isar.writeTxn(() async => await isar.financialTransactions.delete(id));
  }
}