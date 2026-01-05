import 'package:isar/isar.dart';
import '../local_db/isar_db.dart';
import '../models/recurring_movement.dart';
import '../models/enums.dart';

class RecurringDao {
  final IsarService isarService;

  RecurringDao(this.isarService);

  // Crear una nueva regla recurrente
  Future<void> addRecurringMovement(RecurringMovement movement) async {
    final isar = await isarService.db;
    await isar.writeTxn(() async {
      await isar.recurringMovements.put(movement);
    });
  }

  // Obtener solo los ingresos fijos activos
  Future<List<RecurringMovement>> getActiveRecurringIncomes() async {
    final isar = await isarService.db;
    return await isar.recurringMovements
        .filter()
        .typeEqualTo(TransactionType.income)
        .findAll();
  }

  // Escuchar cambios en tiempo real
  Stream<List<RecurringMovement>> watchRecurringIncomes() async* {
    final isar = await isarService.db;
    yield* isar.recurringMovements
        .filter()
        .typeEqualTo(TransactionType.income)
        .watch(fireImmediately: true);
  }

  // --- MÉTODO AGREGADO (CORRECCIÓN) ---
  // Necesario para el debug_time_warp.dart
  Future<List<RecurringMovement>> getAllRecurringMovements() async {
    final isar = await isarService.db;
    return await isar.recurringMovements.where().findAll();
  }
  // ------------------------------------

  // Proyección mensual
  Stream<double> watchProjectedMonthlyIncome() async* {
    final isar = await isarService.db;
    
    yield* isar.recurringMovements
        .filter()
        .typeEqualTo(TransactionType.income)
        .watch(fireImmediately: true)
        .map((movements) {
          double totalProjection = 0;
          for (var movement in movements) {
            double baseAmount = movement.paymentAmounts?.fold<double>(
              0.0, (sum, item) => sum + item) ?? 0.0;

            switch (movement.frequency) {
              case Frequency.daily: totalProjection += baseAmount * 30; break;
              case Frequency.weekly: totalProjection += baseAmount * 4; break;
              case Frequency.biweekly: totalProjection += baseAmount; break;
              case Frequency.monthly: totalProjection += baseAmount; break;
              default: break;
            }
          }
          return totalProjection;
        });
  }

  // Borrar regla
  Future<void> deleteRecurringMovement(Id id) async {
    final isar = await isarService.db;
    await isar.writeTxn(() async {
      await isar.recurringMovements.delete(id);
    });
  }
}