import 'package:isar/isar.dart';
import '../local_db/isar_db.dart';
import '../models/expense.dart';
import '../models/category.dart';

class ExpenseDao {
  final IsarService isarService;

  ExpenseDao(this.isarService);

  // 1. Guardar un gasto (Fijo o Extra)
  Future<void> addExpense(Expense expense, Category category) async {
    final isar = await isarService.db;
    await isar.writeTxn(() async {
      await isar.expenses.put(expense);
      expense.category.value = category; // Enlazamos con la categoría
      await expense.category.save();
    });
  }

  // 2. Ver historial completo (Mix de fijos y extras, ordenados por fecha)
  Stream<List<Expense>> watchAllExpenses() async* {
    final isar = await isarService.db;
    yield* isar.expenses.where().sortByDateDesc().watch(fireImmediately: true);
  }

  // 3. Borrar gasto
  Future<void> deleteExpense(Id id) async {
    final isar = await isarService.db;
    await isar.writeTxn(() async {
      await isar.expenses.delete(id);
    });
  }

  // 4. Sumar gastos del MES ACTUAL (Para el Header Rojo)
  Stream<double> watchTotalExpenseThisMonth() async* {
    final isar = await isarService.db;
    
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    yield* isar.expenses
        .filter()
        .dateBetween(startOfMonth, endOfMonth)
        .watch(fireImmediately: true)
        .map((expenses) {
          if (expenses.isEmpty) return 0.0;
          return expenses.fold(0.0, (sum, item) => sum + item.amount);
        });
  }
}