import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local_db/isar_db.dart';
import '../../data/daos/transaction_dao.dart';
import '../../data/daos/recurring_dao.dart';
// IMPORTAMOS LOS NUEVOS DAOS
import '../../data/daos/expense_dao.dart';
import '../../data/daos/category_dao.dart';
import '../../data/daos/debt_dao.dart';
import '../../data/models/debt.dart';
import '../../data/models/transaction.dart';

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
  // ✅ CORRECCIÓN: El DAO de recurrentes original no necesita `ref`.
  return RecurringDao(isarService);
});

// 4. Proveedor del DAO de Gastos (NUEVO)
final expenseDaoProvider = Provider<ExpenseDao>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  // Le pasamos el servicio de DB y la referencia `ref` completa para que el DAO pueda usarla.
  return ExpenseDao(isarService, ref);
});

// 5. Proveedor del DAO de Categorías (NUEVO)
final categoryDaoProvider = Provider<CategoryDao>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return CategoryDao(isarService);
});

// 6. Proveedor del Stream de Categorías de Gastos (NUEVO)
final expenseCategoriesProvider = StreamProvider((ref) {
  final dao = ref.watch(categoryDaoProvider);
  return dao.watchExpenseCategories();
});

// 7. Proveedor del DAO de Deudas (NUEVO)
final debtDaoProvider = Provider<DebtDao>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return DebtDao(isarService, ref);
});

// 8. Proveedor del Stream de Deudas (NUEVO)
final allDebtsProvider = StreamProvider<List<Debt>>((ref) {
  final dao = ref.watch(debtDaoProvider);
  return dao.watchAllDebts();
});

// 9. Proveedor del Stream de Transacciones para una Deuda (NUEVO)
final debtTransactionsProvider = StreamProvider.family<List<FinancialTransaction>, int>((ref, debtId) {
  final dao = ref.watch(debtDaoProvider);
  return dao.watchTransactionsForDebt(debtId);
});