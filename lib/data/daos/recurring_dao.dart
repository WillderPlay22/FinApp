import 'package:isar/isar.dart';
import '../local_db/isar_db.dart';
import '../models/recurring_movement.dart';
import '../models/enums.dart';

class RecurringDao {
  final IsarService isarService;

  RecurringDao(this.isarService);

  // Crear una nueva regla recurrente (Ej: Sueldo Quincenal)
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

  // Calcular cuánto dinero deberías recibir al mes (Proyección)
  Stream<double> watchProjectedMonthlyIncome() async* {
    final isar = await isarService.db;
    
    yield* isar.recurringMovements
        .filter()
        .typeEqualTo(TransactionType.income)
        .watch(fireImmediately: true)
        .map((movements) {
          double totalProjection = 0;

          for (var movement in movements) {
            // CORRECCIÓN 1: Especificamos tipos explícitos <double> y (double sum, double item)
            // para asegurar que Dart sepa que no son nulos.
            double baseAmount = movement.paymentAmounts?.fold<double>(
              0.0, 
              (double sum, double item) => sum + item
            ) ?? 0.0;

            // Ajustamos según la frecuencia para tener un estimado mensual
            switch (movement.frequency) {
              case Frequency.daily:
                totalProjection += baseAmount * 30; // Aprox mes
                break;
              case Frequency.weekly:
                totalProjection += baseAmount * 4; // Aprox mes
                break;
              case Frequency.biweekly:
                // El baseAmount ya incluye la suma de los 2 pagos (15 y último)
                totalProjection += baseAmount; 
                break;
              case Frequency.monthly:
                totalProjection += baseAmount;
                break;
              // CORRECCIÓN 2: Agregamos 'default' para cubrir cualquier otro caso (como Frequency.none)
              default:
                break;
            }
          }
          return totalProjection;
        });
  }

  // ... (código anterior)

  // NUEVO: Borrar una regla de ingreso fijo
  Future<void> deleteRecurringMovement(Id id) async {
    final isar = await isarService.db;
    await isar.writeTxn(() async {
      await isar.recurringMovements.delete(id);
    });
  }
}