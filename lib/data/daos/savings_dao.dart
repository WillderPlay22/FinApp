import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local_db/isar_db.dart';
import '../models/saving.dart';
import '../models/transaction.dart';
import '../models/enums.dart';
import '../models/expense.dart';
import '../models/recurring_movement.dart';
import '../../date_utils.dart';
import '../../logic/providers/time_provider.dart';

class SavingsDao {
  final IsarService isarService;
  final Ref ref;

  SavingsDao(this.isarService, this.ref);

  // 1. Guardar/Crear Ahorro
  Future<void> saveSaving(Saving saving) async {
    final isar = await isarService.db;
    await isar.writeTxn(() async {
      await isar.savings.put(saving);
    });
  }

  // 1.5 Actualizar Ahorro
  Future<void> updateSaving(Saving saving) async {
    final isar = await isarService.db;
    await isar.writeTxn(() async {
      await isar.savings.put(saving);
    });
  }

  // 2. Observar todos los ahorros
  Stream<List<Saving>> watchAllSavings() async* {
    final isar = await isarService.db;
    yield* isar.savings.where().watch(fireImmediately: true);
  }

  // 3. Observar un ahorro específico
  Stream<Saving?> watchSaving(int id) async* {
    final isar = await isarService.db;
    yield* isar.savings.watchObject(id, fireImmediately: true);
  }

  // 3.5 Observar historial de un ahorro específico
  Stream<List<FinancialTransaction>> watchSavingTransactions(int savingId) async* {
    final isar = await isarService.db;
    yield* isar.financialTransactions
        .filter()
        .typeEqualTo(TransactionType.saving)
        .relatedSaving((q) => q.idEqualTo(savingId)) // ✅ CORREGIDO: Usar el vínculo real
        .sortByDateDesc()
        .watch(fireImmediately: true);
  }

  // 4. Registrar un depósito (Transacción de Ahorro)
  Future<void> depositToSaving(Saving saving, double amount) async {
    final isar = await isarService.db;
    final now = ref.read(nowProvider);

    final transaction = FinancialTransaction()
      ..amount = amount
      ..date = now
      ..note = "Ahorro: ${saving.name}"
      ..type = TransactionType.saving // Nuevo tipo
      ..categoryName = "Ahorro"
      ..categoryIconCode = saving.iconCode
      ..colorValue = saving.colorValue
      ..note = "Depósito a: ${saving.name}"
      ..relatedSaving.value = saving; // ✅ VINCULAMOS EL AHORRO

    await isar.writeTxn(() async {
      // Actualizar monto actual del ahorro
      saving.currentAmount += amount;
      await isar.savings.put(saving);
      
      // Guardar transacción
      await isar.financialTransactions.put(transaction);
      await transaction.relatedSaving.save(); // ✅ GUARDAMOS EL VÍNCULO
    });
  }

  // 5. Calcular Proyección Neta del Mes (Remanente)
  // Fórmula: (Ingresos Fijos + Extras) - (Gastos Fijos + Extras)
  Future<double> calculateMonthlyNetProjection() async {
    final isar = await isarService.db;
    final now = ref.read(nowProvider);
    final range = getCycleDateRange(now, Frequency.monthly);

    // A. INGRESOS
    // A1. Fijos (Proyección total de la configuración)
    final recurringIncomes = await isar.recurringMovements.filter().typeEqualTo(TransactionType.income).findAll();
    double projectedIncome = 0;
    for (var m in recurringIncomes) {
      projectedIncome += (m.paymentAmounts ?? []).fold(0.0, (sum, e) => sum + e);
    }
    // A2. Extras (Ya ejecutados este mes)
    final extraIncomes = await isar.financialTransactions
        .filter()
        .typeEqualTo(TransactionType.income)
        .isRecurringEqualTo(false) // Solo extras puros
        .dateBetween(range.start, range.end)
        .findAll();
    double extraIncomeTotal = extraIncomes.fold(0, (sum, t) => sum + t.amount);

    // B. GASTOS
    // B1. Fijos (Proyección mensualizada)
    final fixedExpenses = await isar.expenses.filter().isRecurringEqualTo(true).findAll();
    double projectedExpense = 0;
    for (var e in fixedExpenses) {
      // Lógica simple de mensualización
      if (e.frequency == Frequency.monthly) {
        projectedExpense += e.amount;
      } else if (e.frequency == Frequency.biweekly) {
        projectedExpense += e.amount * 2;
      } else if (e.frequency == Frequency.weekly) {
        projectedExpense += e.amount * 4;
      } else if (e.frequency == Frequency.daily) {
        projectedExpense += e.amount * 30;
      }
    }
    // B2. Extras (Ya ejecutados este mes)
    final extraExpenses = await isar.financialTransactions
        .filter()
        .typeEqualTo(TransactionType.expense)
        .isRecurringEqualTo(false)
        .dateBetween(range.start, range.end)
        .findAll();
    double extraExpenseTotal = extraExpenses.fold(0, (sum, t) => sum + t.amount);

    // C. CÁLCULO FINAL
    final totalIncome = projectedIncome + extraIncomeTotal;
    final totalExpense = projectedExpense + extraExpenseTotal;
    
    return (totalIncome - totalExpense);
  }

  // 6. Borrar Ahorro
  Future<void> deleteSaving(int id) async {
    final isar = await isarService.db;
    await isar.writeTxn(() async => await isar.savings.delete(id));
  }

  // 7. Obtener Progreso Mensual (Para la tarjeta de resumen)
  Stream<({double expected, double executed, int totalPlans, int executedPlans})> watchMonthlyProgress() async* {
    final isar = await isarService.db;
    final now = ref.read(nowProvider);
    final range = getCycleDateRange(now, Frequency.monthly);

    // Escuchamos cambios en Ahorros y Transacciones
    yield* isar.financialTransactions
        .filter()
        .typeEqualTo(TransactionType.saving)
        .dateBetween(range.start, range.end)
        .watch(fireImmediately: true)
        .asyncMap((transactions) async {
          
          final savings = await isar.savings.where().findAll();
          
          // Identificar qué ahorros han recibido depósitos este mes
          final savingsWithDepositsThisMonth = <int>{};
          for (var t in transactions) {
            await t.relatedSaving.load();
            if (t.relatedSaving.value != null) {
              savingsWithDepositsThisMonth.add(t.relatedSaving.value!.id);
            }
          }
          
          double expectedTotal = 0.0;
          double executedTotal = 0.0;
          int totalPlans = 0;
          int executedPlans = 0;

          // 1. Calcular lo esperado
          final netProjection = await calculateMonthlyNetProjection();
          final baseProjection = netProjection > 0 ? netProjection : 0.0;

          for (var s in savings) {
            final isGoal = s.type == SavingType.goal;
            final target = s.targetAmount ?? 0.0;
            // ¿Está completado?
            final isCompleted = isGoal && target > 0 && s.currentAmount >= target;
            // ¿Tuvo actividad este mes?
            final contributedThisMonth = savingsWithDepositsThisMonth.contains(s.id);

            // LÓGICA DE CICLO:
            // Incluimos el ahorro en el plan mensual si:
            // 1. NO está completado (aún requiere cuotas).
            // 2. ESTÁ completado PERO se contribuyó este mes (se completó recién).
            // Si se completó el mes pasado y no se tocó este mes, se ignora.
            if (!isCompleted || contributedThisMonth) {
              totalPlans++;

              // Sumar al esperado
              if (s.method == SavingMethod.fixed) {
                expectedTotal += (s.fixedAmount ?? 0.0);
              } else {
                expectedTotal += baseProjection * ((s.percentage ?? 0.0) / 100);
              }

              // Sumar al ejecutado si corresponde
              if (contributedThisMonth) {
                executedPlans++;
                // Sumamos solo las transacciones de ESTE ahorro
                final txs = transactions.where((t) => t.relatedSaving.value?.id == s.id);
                for (var t in txs) {
                  executedTotal += t.amount;
                }
              }
            }
          }

          return (expected: expectedTotal, executed: executedTotal, totalPlans: totalPlans, executedPlans: executedPlans);
        });
  }
}