import 'package:isar/isar.dart';
import '../local_db/isar_db.dart';
import '../models/category.dart';
import '../models/expense.dart';

class CategoryDao {
  final IsarService isarService;

  CategoryDao(this.isarService);

  // Crear nueva categoría
  Future<void> addCategory(Category category) async {
    final isar = await isarService.db;
    await isar.writeTxn(() async {
      await isar.categorys.put(category);
    });
  }

  // Obtener todas las categorías de Gasto
  Stream<List<Category>> watchExpenseCategories() async* {
    final isar = await isarService.db;
    yield* isar.categorys
        .filter()
        .isExpenseEqualTo(true)
        .watch(fireImmediately: true);
  }

  // LÓGICA AVANZADA: Calcular el total gastado por categoría
  Future<double> getCategoryFixedTotal(Id categoryId) async {
    final isar = await isarService.db;
    
    // Buscamos gastos que pertenezcan a esta categoría Y sean recurrentes (fijos)
    final expenses = await isar.expenses
        .filter()
        .category((q) => q.idEqualTo(categoryId))
        .isRecurringEqualTo(true)
        .findAll();

    if (expenses.isEmpty) return 0.0;
    
    // CORRECCIÓN AQUÍ: Agregamos <double> para evitar la confusión de tipos
    return expenses.fold<double>(0.0, (sum, item) => sum + item.amount);
  }
}