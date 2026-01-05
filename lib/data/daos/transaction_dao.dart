import 'package:isar/isar.dart';
import '../local_db/isar_db.dart';
import '../models/transaction.dart';
import '../models/enums.dart';

class TransactionDao {
  final IsarService isarService;

  TransactionDao(this.isarService);

  // Guardar transacción
  Future<void> addTransaction(FinancialTransaction transaction) async {
    final isar = await isarService.db;
    await isar.writeTxn(() async {
      await isar.financialTransactions.put(transaction);
    });
  }

  // Verificar si ya existe un pago
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

  // Leer todas
  Future<List<FinancialTransaction>> getAllTransactions() async {
    final isar = await isarService.db;
    return await isar.financialTransactions
        .where()
        .sortByDateDesc()
        .findAll();
  }

  // Escuchar cambios
  Stream<List<FinancialTransaction>> watchTransactions() async* {
    final isar = await isarService.db;
    yield* isar.financialTransactions
        .where()
        .sortByDateDesc()
        .watch(fireImmediately: true);
  }

  // Total Ingresos Mes
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
}
// ⚠️ PROVIDER ELIMINADO AQUÍ (Ya está en database_providers.dart)