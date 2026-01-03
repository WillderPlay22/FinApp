import 'package:isar/isar.dart';
import '../local_db/isar_db.dart';
import '../models/transaction.dart';
import '../models/enums.dart'; // <--- ESTA ES LA LÍNEA QUE FALTABA

class TransactionDao {
  final IsarService isarService;

  TransactionDao(this.isarService);

  // Guardar una nueva transacción (Ingreso o Gasto)
  Future<void> addTransaction(FinancialTransaction transaction) async {
    final isar = await isarService.db;
    await isar.writeTxn(() async {
      await isar.financialTransactions.put(transaction);
    });
  }

  // Leer todas las transacciones ordenadas por fecha (lo más nuevo primero)
  Future<List<FinancialTransaction>> getAllTransactions() async {
    final isar = await isarService.db;
    return await isar.financialTransactions
        .where()
        .sortByDateDesc()
        .findAll();
  }

  // Escuchar cambios en tiempo real
  Stream<List<FinancialTransaction>> watchTransactions() async* {
    final isar = await isarService.db;
    yield* isar.financialTransactions
        .where()
        .sortByDateDesc()
        .watch(fireImmediately: true);
  }

  // Escuchar el total de dinero ingresado en el MES ACTUAL
  Stream<double> watchTotalIncomeThisMonth() async* {
    final isar = await isarService.db;
    
    // Calculamos el inicio y fin del mes actual
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    // Observamos cambios y sumamos
    yield* isar.financialTransactions
        .filter()
        .typeEqualTo(TransactionType.income) // Ahora sí reconocerá esto
        .dateBetween(startOfMonth, endOfMonth)
        .watch(fireImmediately: true)
        .map((transactions) {
          if (transactions.isEmpty) return 0.0;
          return transactions.fold(0.0, (sum, item) => sum + item.amount);
        });
  }
}