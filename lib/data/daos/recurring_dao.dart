import 'package:isar/isar.dart';
import '../local_db/isar_db.dart';
import '../models/recurring_movement.dart';
import '../models/transaction.dart';
import '../models/enums.dart';

class IncomeCycleStatus {
  final double totalCollected;
  final int paymentCount;
  final bool isFullyPaid;

  IncomeCycleStatus({
    required this.totalCollected, 
    required this.paymentCount, 
    required this.isFullyPaid
  });
}

class RecurringDao {
  final IsarService isarService;

  RecurringDao(this.isarService);

  // 1. Guardar
  Future<void> addRecurringMovement(RecurringMovement movement) async {
    final isar = await isarService.db;
    await isar.writeTxn(() async {
      await isar.recurringMovements.put(movement);
    });
  }

  // 2. Escuchar lista
  Stream<List<RecurringMovement>> watchRecurringIncomes() async* {
    final isar = await isarService.db;
    yield* isar.recurringMovements
        .filter()
        .typeEqualTo(TransactionType.income)
        .watch(fireImmediately: true);
  }

  // ✅ 3. PROYECCIÓN MENSUAL CORREGIDA
  // Ahora suma todos los montos configurados en 'paymentAmounts'
  Stream<double> watchProjectedMonthlyIncome() async* {
    final isar = await isarService.db;
    yield* isar.recurringMovements
        .filter()
        .typeEqualTo(TransactionType.income)
        .watch(fireImmediately: true)
        .map((movements) {
          double totalProjection = 0;
          for (var movement in movements) {
            
            // Sumamos los montos configurados en la lista (ej: [100, 150] = 250)
            double cycleSum = movement.paymentAmounts?.fold(0.0, (sum, val) => sum! + val) ?? 0.0;

            switch (movement.frequency) {
              case Frequency.daily: 
                totalProjection += cycleSum * 30; 
                break;
              case Frequency.weekly: 
                totalProjection += cycleSum * 4; 
                break;
              case Frequency.biweekly: 
                // Quincenal ya tiene los 2 pagos en la lista, así que el ciclo ES el mes
                totalProjection += cycleSum; 
                break;
              case Frequency.monthly: 
                totalProjection += cycleSum; 
                break;
              default: 
                totalProjection += cycleSum; 
                break;
            }
          }
          return totalProjection;
        });
  }

  // 4. Obtener todos (Para Notificaciones)
  Future<List<RecurringMovement>> getAllRecurringMovements() async {
    final isar = await isarService.db;
    return await isar.recurringMovements.where().findAll();
  }

  // 5. Estado del Ciclo
  Stream<IncomeCycleStatus> watchIncomeCycleStatus(RecurringMovement movement) async* {
    final isar = await isarService.db;
    final now = DateTime.now();
    DateTime start, end;
    int maxPayments = 1;

    switch (movement.frequency) {
      case Frequency.weekly:
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        break;
      case Frequency.biweekly:
        if (now.day <= 15) {
          start = DateTime(now.year, now.month, 1);
          end = DateTime(now.year, now.month, 15, 23, 59, 59);
        } else {
          start = DateTime(now.year, now.month, 16);
          end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        }
        break;
      default:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
    }

    yield* isar.financialTransactions
        .filter()
        .parentRecurringIdEqualTo(movement.id)
        .and()
        .typeEqualTo(TransactionType.income)
        .and()
        .dateBetween(start, end)
        .watch(fireImmediately: true)
        .map((transactions) {
          double total = transactions.fold(0.0, (sum, t) => sum + t.amount);
          int count = transactions.length;
          return IncomeCycleStatus(
            totalCollected: total,
            paymentCount: count,
            isFullyPaid: count >= maxPayments
          );
        });
  }

  // 6. Marcar como cobrado
  Future<void> markAsCollected(RecurringMovement movement, {double? customAmount}) async {
    final isar = await isarService.db;
    final now = DateTime.now();
    double baseAmount = customAmount ?? (movement.paymentAmounts?.isNotEmpty == true ? movement.paymentAmounts!.first : 0.0);

    final newTx = FinancialTransaction()
      ..amount = baseAmount
      ..note = movement.title 
      ..date = now 
      ..type = TransactionType.income
      ..categoryName = "Ingreso Fijo"
      ..categoryIconCode = 0xf0d6
      ..colorValue = 0xFF4CAF50
      ..parentRecurringId = movement.id; 

    await isar.writeTxn(() async {
      await isar.financialTransactions.put(newTx);
    });
  }

  // 7. Borrar
  Future<void> deleteRecurringMovement(Id id) async {
    final isar = await isarService.db;
    await isar.writeTxn(() async {
      await isar.recurringMovements.delete(id);
    });
  }
}