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

  // ✅ NUEVO: Actualizar categoría existente
  Future<void> updateCategory(Category category) async {
    final isar = await isarService.db;
    await isar.writeTxn(() async {
      await isar.categorys.put(category);
    });
  }

  // ✅ NUEVO: Borrar categoría y todos sus gastos asociados (Cascada)
  Future<void> deleteCategoryWithExpenses(Id categoryId) async {
    final isar = await isarService.db;
    await isar.writeTxn(() async {
      // 1. Borrar todos los gastos fijos que pertenecen a esta categoría
      await isar.expenses
          .filter()
          .category((q) => q.idEqualTo(categoryId))
          .deleteAll();
      
      // 2. Borrar la categoría
      await isar.categorys.delete(categoryId);
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

  // ✅ NUEVO: Observa una categoría específica por su ID
  Stream<Category?> watchCategory(int categoryId) async* {
    final isar = await isarService.db;
    // watchObject emite un nuevo valor cuando el objeto con ese ID cambia,
    // o null si es borrado.
    yield* isar.categorys.watchObject(categoryId, fireImmediately: true);
  }

  // Calcular el total gastado por categoría
  Future<double> getCategoryFixedTotal(Id categoryId) async {
    final isar = await isarService.db;
    
    // Buscamos gastos que pertenezcan a esta categoría Y sean recurrentes (fijos)
    final expenses = await isar.expenses
        .filter()
        .category((q) => q.idEqualTo(categoryId))
        .isRecurringEqualTo(true)
        .findAll();

    if (expenses.isEmpty) return 0.0;
    
    // Sumamos los montos
    return expenses.fold<double>(0.0, (sum, item) => sum + item.amount);
  }
}