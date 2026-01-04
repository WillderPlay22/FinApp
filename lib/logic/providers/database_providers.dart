import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local_db/isar_db.dart';
import '../../data/daos/transaction_dao.dart';
import '../../data/daos/recurring_dao.dart';
// IMPORTAMOS LOS NUEVOS DAOS
import '../../data/daos/expense_dao.dart';
import '../../data/daos/category_dao.dart';

// 1. Proveedor de la conexión a Base de Datos
final isarServiceProvider = Provider<IsarService>((ref) {
  return IsarService();
});

// 2. Proveedor del DAO de Transacciones (Ingresos Extras)
final transactionDaoProvider = Provider<TransactionDao>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return TransactionDao(isarService);
});

// 3. Proveedor del DAO de Recurrentes (Ingresos Fijos)
final recurringDaoProvider = Provider<RecurringDao>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return RecurringDao(isarService);
});

// 4. Proveedor del DAO de Gastos (NUEVO)
final expenseDaoProvider = Provider<ExpenseDao>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return ExpenseDao(isarService);
});

// 5. Proveedor del DAO de Categorías (NUEVO)
final categoryDaoProvider = Provider<CategoryDao>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return CategoryDao(isarService);
});