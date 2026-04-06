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
import '../models/exchange_rate.dart';
import '../models/currency_settings.dart';

class SavingsDao {
  final IsarService isarService;
  final Ref ref;

  /// Obtiene la tasa de cambio más reciente desde Isar.
  Future<double?> _getLatestRate() async {
    final isar = await isarService.db;
    final settings = await isar.currencySettings.get(1);
    if (settings == null || !settings.isMultiCurrencyEnabled) return null;
    final rate = await isar.exchangeRates.where().sortByDateDesc().findFirst();
    return rate?.rate;
  }

  /// Convierte un monto a moneda de referencia (USD) si está en moneda local (BS).
  double _toReference(double amount, String? currencyCode, double? rate) {
    if (rate == null || currencyCode == null || currencyCode == 'USD') return amount;
    if (currencyCode == 'BS') return amount / rate;
    return amount;
  }

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
  /// [exchangeRate] y [currencyCode] son opcionales para multi-moneda.
  Future<void> depositToSaving(
    Saving saving,
    double amount, {
    double? exchangeRate,
    String? currencyCode,
  }) async {
    final isar = await isarService.db;
    final now = ref.read(nowProvider);
    final effectiveCurrency = currencyCode ?? saving.currencyCode;

    final transaction = FinancialTransaction()
      ..amount = amount
      ..date = now
      ..note = "Depósito a: ${saving.name}"
      ..type = TransactionType.saving
      ..categoryName = "Ahorro"
      ..categoryIconCode = saving.iconCode
      ..colorValue = saving.colorValue
      ..currencyCode = effectiveCurrency
      ..exchangeRateAtTime = exchangeRate
      ..relatedSaving.value = saving;

    // Pre-calcular montos en ambas monedas si hay tasa
    if (exchangeRate != null && effectiveCurrency != null) {
      if (effectiveCurrency == 'USD') {
        transaction.amountInReferenceCurrency = amount;
        transaction.amountInLocalCurrency = amount * exchangeRate;
      } else if (effectiveCurrency == 'BS') {
        transaction.amountInLocalCurrency = amount;
        transaction.amountInReferenceCurrency = amount / exchangeRate;
      }
    }

    await isar.writeTxn(() async {
      // Actualizar monto actual del ahorro
      saving.currentAmount += amount;
      await isar.savings.put(saving);

      // Guardar transacción
      await isar.financialTransactions.put(transaction);
      await transaction.relatedSaving.save();
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
    final rate = await _getLatestRate();
    double projectedIncome = 0;
    for (var m in recurringIncomes) {
      final cycleSum = (m.paymentAmounts ?? []).fold(0.0, (sum, e) => sum + e);
      projectedIncome += _toReference(cycleSum, m.currencyCode, rate);
    }
    // A2. Extras (Ya ejecutados este mes)
    final extraIncomes = await isar.financialTransactions
        .filter()
        .typeEqualTo(TransactionType.income)
        .isRecurringEqualTo(false) // Solo extras puros
        .dateBetween(range.start, range.end)
        .findAll();
    double extraIncomeTotal = extraIncomes.fold(0, (sum, t) => sum + t.referenceAmountWithRate(rate));

    // B. GASTOS
    // B1. Fijos (Proyección mensualizada)
    final fixedExpenses = await isar.expenses.filter().isRecurringEqualTo(true).findAll();
    double projectedExpense = 0;
    for (var e in fixedExpenses) {
      // Lógica simple de mensualización
      double monthlyAmt;
      if (e.frequency == Frequency.monthly) {
        monthlyAmt = e.amount;
      } else if (e.frequency == Frequency.biweekly) {
        monthlyAmt = e.amount * 2;
      } else if (e.frequency == Frequency.weekly) {
        monthlyAmt = e.amount * 4;
      } else if (e.frequency == Frequency.daily) {
        monthlyAmt = e.amount * 30;
      } else {
        monthlyAmt = e.amount;
      }
      projectedExpense += _toReference(monthlyAmt, e.currencyCode, rate);
    }
    // B2. Extras (Ya ejecutados este mes)
    final extraExpenses = await isar.financialTransactions
        .filter()
        .typeEqualTo(TransactionType.expense)
        .isRecurringEqualTo(false)
        .dateBetween(range.start, range.end)
        .findAll();
    double extraExpenseTotal = extraExpenses.fold(0, (sum, t) => sum + t.referenceAmountWithRate(rate));

    // C. CÁLCULO FINAL
    final totalIncome = projectedIncome + extraIncomeTotal;
    final totalExpense = projectedExpense + extraExpenseTotal;
    
    return (totalIncome - totalExpense);
  }

  // 5.5 Retirar fondos de un ahorro (fuente única de retiros)
  Future<void> withdrawFromSaving(
    Saving saving,
    double amount, {
    double? exchangeRate,
    String? currencyCode,
  }) async {
    if (amount <= 0 || amount > saving.currentAmount) return;
    final isar = await isarService.db;
    final now = ref.read(nowProvider);
    final effectiveCurrency = currencyCode ?? saving.currencyCode;

    final transaction = FinancialTransaction()
      ..amount = -amount // Negativo para distinguir retiros de depósitos
      ..date = now
      ..note = "Retiro de: ${saving.name}"
      ..type = TransactionType.saving
      ..categoryName = "Ahorro"
      ..categoryIconCode = saving.iconCode
      ..colorValue = saving.colorValue
      ..currencyCode = effectiveCurrency
      ..exchangeRateAtTime = exchangeRate
      ..relatedSaving.value = saving;

    if (exchangeRate != null && effectiveCurrency != null) {
      if (effectiveCurrency == 'USD') {
        transaction.amountInReferenceCurrency = -amount;
        transaction.amountInLocalCurrency = -amount * exchangeRate;
      } else if (effectiveCurrency == 'BS') {
        transaction.amountInLocalCurrency = -amount;
        transaction.amountInReferenceCurrency = -amount / exchangeRate;
      }
    }

    await isar.writeTxn(() async {
      saving.currentAmount -= amount;
      await isar.savings.put(saving);
      await isar.financialTransactions.put(transaction);
      await transaction.relatedSaving.save();
    });
  }

  // 6. Borrar Ahorro
  Future<void> deleteSaving(int id) async {
    final isar = await isarService.db;
    await isar.writeTxn(() async => await isar.savings.delete(id));
  }

  // 7. Obtener Progreso Mensual (Para la tarjeta de resumen)
  // [now] se recibe como parámetro para que el provider lo proporcione
  // reactivamente — si cambia de mes, el stream se recrea automáticamente.
  Stream<({double expected, double executed, int totalPlans, int executedPlans})> watchMonthlyProgress(DateTime now) async* {
    final isar = await isarService.db;
    final range = getCycleDateRange(now, Frequency.monthly);

    // Escuchamos cambios en Ahorros y Transacciones
    yield* isar.financialTransactions
        .filter()
        .typeEqualTo(TransactionType.saving)
        .dateBetween(range.start, range.end)
        .watch(fireImmediately: true)
        .asyncMap((transactions) async {
          final rate = await _getLatestRate();
          final savings = await isar.savings.where().findAll();

          // Cargar relaciones para todas las transacciones
          for (var t in transactions) {
            await t.relatedSaving.load();
          }

          double expectedTotal = 0.0;
          double executedTotal = 0.0;
          int totalPlans = 0;
          int executedPlans = 0;

          // Solo depósitos (amount > 0), ignorar retiros para el progreso mensual
          final deposits = transactions.where((t) => t.amount > 0).toList();

          // Identificar ahorros con depósitos (no retiros) este mes
          final savingsWithDepositsThisMonth = <int>{};
          for (var t in deposits) {
            if (t.relatedSaving.value != null) {
              savingsWithDepositsThisMonth.add(t.relatedSaving.value!.id);
            }
          }

          // 1. Calcular lo esperado
          final netProjection = await calculateMonthlyNetProjection();
          final baseProjection = netProjection > 0 ? netProjection : 0.0;

          for (var s in savings) {
            final isGoal = s.type == SavingType.goal;
            final target = s.targetAmount ?? 0.0;
            // ¿Está completado?
            final isCompleted = isGoal && target > 0 && s.currentAmount >= target;
            // ¿Tuvo depósitos este mes?
            final contributedThisMonth = savingsWithDepositsThisMonth.contains(s.id);

            // Incluir en el plan si no está completado, o si se completó este mes
            if (!isCompleted || contributedThisMonth) {
              totalPlans++;

              // Sumar al esperado
              if (s.method == SavingMethod.fixed) {
                expectedTotal += (s.fixedAmount ?? 0.0);
              } else {
                expectedTotal += baseProjection * ((s.percentage ?? 0.0) / 100);
              }

              // Sumar al ejecutado (solo depósitos de este ahorro)
              if (contributedThisMonth) {
                executedPlans++;
                final txs = deposits.where((t) => t.relatedSaving.value?.id == s.id);
                for (var t in txs) {
                  executedTotal += t.referenceAmountWithRate(rate);
                }
              }
            }
          }

          return (expected: expectedTotal, executed: executedTotal, totalPlans: totalPlans, executedPlans: executedPlans);
        });
  }
}