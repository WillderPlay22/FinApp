import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local_db/isar_db.dart';
import '../../data/daos/transaction_dao.dart';
import '../../data/daos/recurring_dao.dart';

// 1. Proveedor de la conexión a Base de Datos
final isarServiceProvider = Provider<IsarService>((ref) {
  return IsarService();
});

// 2. Proveedor del DAO de Transacciones
final transactionDaoProvider = Provider<TransactionDao>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return TransactionDao(isarService);
});

// 3. Proveedor del DAO de Recurrentes
final recurringDaoProvider = Provider<RecurringDao>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return RecurringDao(isarService);
});