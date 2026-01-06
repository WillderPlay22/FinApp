import 'package:isar/isar.dart';
import '../local_db/isar_db.dart';
import '../models/transaction.dart';
import '../models/enums.dart';

class TransactionDao {
  final IsarService isarService;

  TransactionDao(this.isarService);

  // 1. Guardar transacción (Sirve para Ingresos y Gastos Extras)
  Future<void> addTransaction(FinancialTransaction transaction) async {
    final isar = await isarService.db;
    await isar.writeTxn(() async {
      await isar.financialTransactions.put(transaction);
    });
  }

  // 2. Verificar si ya existe un pago (Para lógica de recurrentes)
  Future<bool> isPaymentMade({
    required int recurringId, 
    required DateTime start, 
    required DateTime end
  }) async {
    final isar = await isarService.db;
    
    final count = await isar.financialTransactions
        .filter()
        .parentRecurringIdEqualTo(recurringId)
        .and()
        .dateBetween(start, end)
        .count();

    return count > 0;
  }

  // ✅ 3. NUEVO: CONTAR PAGOS (Necesario para la corrección quincenal)
  Future<int> countPayments({
    required int recurringId, 
    required DateTime start, 
    required DateTime end
  }) async {
    final isar = await isarService.db;
    
    return await isar.financialTransactions
        .filter()
        .parentRecurringIdEqualTo(recurringId)
        .and()
        .dateBetween(start, end)
        .count();
  }

  // 4. Leer SOLO INGRESOS
  Stream<List<FinancialTransaction>> watchIncomeTransactions() async* {
    final isar = await isarService.db;
    yield* isar.financialTransactions
        .filter()
        .typeEqualTo(TransactionType.income)
        .sortByDateDesc()
        .watch(fireImmediately: true);
  }

  // 5. Total Ingresos Mes
  Stream<double> watchTotalIncomeThisMonth() async* {
    final isar = await isarService.db;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    yield* isar.financialTransactions
        .filter()
        .typeEqualTo(TransactionType.income)
        .dateBetween(startOfMonth, endOfMonth)
        .watch(fireImmediately: true)
        .map((transactions) {
          if (transactions.isEmpty) return 0.0;
          return transactions.fold(0.0, (sum, item) => sum + item.amount);
        });
  }

  // 6. BORRAR TRANSACCIÓN (Para el Swipe)
  Future<void> deleteTransaction(int id) async {
    final isar = await isarService.db;
    await isar.writeTxn(() async {
      await isar.financialTransactions.delete(id);
    });
  }
}