import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/enums.dart';
import '../../data/models/expense.dart';
import '../../data/models/debt.dart';
import '../../data/models/transaction.dart';
import '../../data/models/recurring_movement.dart';
import '../../date_utils.dart';
import '../../logic/providers/database_providers.dart';
import '../../logic/providers/time_provider.dart';
import '../../logic/providers/currency_providers.dart';

// Fecha seleccionada para la planificación (Por defecto: Fecha actual)
final planningDateProvider = StateProvider<DateTime>((ref) {
  return ref.watch(nowProvider);
});

// Transacciones Reales del Mes (Para cálculo de flujo de caja en planificación)
final monthRealTransactionsProvider =
    StreamProvider<List<FinancialTransaction>>((ref) async* {
  final expenseDao = ref.watch(expenseDaoProvider);
  final planningDate = ref.watch(planningDateProvider);
  final range = getCycleDateRange(planningDate, Frequency.monthly);

  final extendedStart = range.start.subtract(const Duration(days: 3));
  final extendedEnd = range.end.add(const Duration(days: 3));
  final isar = await expenseDao.isarService.db;
  yield* isar.financialTransactions
      .filter()
      .dateBetween(extendedStart, extendedEnd)
      .watch(fireImmediately: true);
});

// Configuración de la Tabla (Columnas basadas en el Ingreso Principal)
final planningConfigProvider =
    StreamProvider<({int columns, List<double> columnIncomes, Frequency freq})>(
        (ref) async* {
  final isar = await ref.watch(isarServiceProvider).db;
  final exchangeRateService = ref.watch(exchangeRateServiceProvider);

  final query = isar.recurringMovements.where().build();
  await for (final incomes in query.watch(fireImmediately: true)) {
    final currentRate = await exchangeRateService.getCurrentRate();
    final rateValue = currentRate?.rate;
    double toRef(double amount, String? currencyCode) {
      if (rateValue == null || currencyCode == null || currencyCode == 'USD') return amount;
      if (currencyCode == 'BS') return amount / rateValue;
      return amount;
    }

    if (incomes.isEmpty) {
      yield (columns: 1, columnIncomes: [0.0], freq: Frequency.monthly);
      continue;
    }

    RecurringMovement? dominant;
    double maxMonthly = -1;

    for (var inc in incomes) {
      final total = (inc.paymentAmounts ?? []).fold(0.0, (s, e) => s + e);
      final totalRef = toRef(total, inc.currencyCode);
      if (totalRef > maxMonthly) {
        maxMonthly = totalRef;
        dominant = inc;
      }
    }

    if (dominant == null) {
      yield (columns: 1, columnIncomes: [0.0], freq: Frequency.monthly);
      continue;
    }

    final freq = dominant.frequency;
    final amounts = dominant.paymentAmounts ?? [];
    int columns = 1;
    List<double> columnIncomes = [];

    switch (freq) {
      case Frequency.weekly:
        columns = 4;
        if (amounts.isNotEmpty) {
          columnIncomes = List.generate(
              4, (i) => toRef(i < amounts.length ? amounts[i] : amounts.last, dominant!.currencyCode));
        } else {
          columnIncomes = List.filled(4, 0.0);
        }
        break;
      case Frequency.biweekly:
        columns = 2;
        if (amounts.length >= 2) {
          columnIncomes = [toRef(amounts[1], dominant.currencyCode), toRef(amounts[0], dominant.currencyCode)];
        } else if (amounts.isNotEmpty) {
          final refAmt = toRef(amounts[0], dominant.currencyCode);
          columnIncomes = [refAmt, refAmt];
        } else {
          columnIncomes = [0.0, 0.0];
        }
        break;
      default:
        columns = 1;
        columnIncomes = [maxMonthly];
    }

    for (var inc in incomes) {
      if (inc.id == dominant.id) continue;
      final secAmounts = inc.paymentAmounts ?? [];
      final secTotal = secAmounts.fold(0.0, (s, e) => s + e);
      final secTotalRef = toRef(secTotal, inc.currencyCode);
      if (secTotalRef <= 0) continue;

      if (inc.frequency == freq && columns > 1) {
        if (freq == Frequency.biweekly && secAmounts.length >= 2) {
          columnIncomes[0] += toRef(secAmounts[1], inc.currencyCode);
          columnIncomes[1] += toRef(secAmounts[0], inc.currencyCode);
        } else if (freq == Frequency.weekly) {
          for (int i = 0; i < columns; i++) {
            columnIncomes[i] +=
                toRef(i < secAmounts.length ? secAmounts[i] : secAmounts.last, inc.currencyCode);
          }
        }
      } else {
        final perColumn = secTotalRef / columns;
        for (int i = 0; i < columns; i++) {
          columnIncomes[i] += perColumn;
        }
      }
    }

    yield (columns: columns, columnIncomes: columnIncomes, freq: freq);
  }
});

// Controlador de Posiciones con Persistencia (Archivo JSON Local)
class PlanningPositionsController extends StateNotifier<Map<String, int?>> {
  PlanningPositionsController() : super({}) {
    _load();
  }

  static const _fileName = 'planning_layout.json';

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<void> _load() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final Map<String, dynamic> decoded = jsonDecode(jsonString);
        final Map<String, int?> loaded =
            decoded.map((key, value) => MapEntry(key, value as int?));
        state = loaded;
      }
    } catch (e) {
      debugPrint("Error cargando planificación: $e");
    }
  }

  Future<void> _save() async {
    try {
      final file = await _getFile();
      final toSave = Map<String, int>.fromEntries(state.entries
          .where((e) => e.value != null)
          .map((e) => MapEntry(e.key, e.value!)));
      await file.writeAsString(jsonEncode(toSave));
    } catch (e) {
      debugPrint("Error guardando planificación: $e");
    }
  }

  void updatePosition(String id, int? column) {
    final newState = Map<String, int?>.from(state);
    if (column == null) {
      newState.remove(id);
    } else {
      newState[id] = column;
    }
    state = newState;
    _save();
  }
}

final planningPositionsProvider =
    StateNotifierProvider<PlanningPositionsController, Map<String, int?>>(
        (ref) {
  return PlanningPositionsController();
});

// Rangos dinámicos de planificación basados en fechas reales de cobro
final dynamicPeriodRangesProvider = FutureProvider<List<DateRange>>((ref) async {
  final config = await ref.watch(planningConfigProvider.future);
  final planningDate = ref.watch(planningDateProvider);
  // Observar transacciones reales para reactividad (se recalcula al agregar pagos)
  final realTransactions = await ref.watch(monthRealTransactionsProvider.future);

  if (config.columns <= 1) {
    return [
      DateRange(
        DateTime(planningDate.year, planningDate.month, 1),
        DateTime(planningDate.year, planningDate.month + 1, 0, 23, 59, 59),
      ),
    ];
  }

  if (config.columns == 4) {
    final lastDay = DateTime(planningDate.year, planningDate.month + 1, 0).day;
    return List.generate(4, (i) {
      final startDay = 1 + (i * 7);
      final endDay = (startDay + 6).clamp(1, lastDay);
      return DateRange(
        DateTime(planningDate.year, planningDate.month, startDay),
        DateTime(planningDate.year, planningDate.month, endDay, 23, 59, 59),
      );
    });
  }

  // Biweekly (columns == 2): usar transacciones reales
  return _calculateBiweeklyRanges(realTransactions, planningDate);
});

List<DateRange> _calculateBiweeklyRanges(
  List<FinancialTransaction> realTransactions, DateTime planningDate,
) {
  final year = planningDate.year;
  final month = planningDate.month;
  final lastDayOfMonth = DateTime(year, month + 1, 0).day;

  // Filtrar ingresos recurrentes confirmados del mes actual
  final incomeTxs = realTransactions.where((tx) =>
      tx.type == TransactionType.income &&
      tx.isRecurring &&
      tx.parentRecurringId != null &&
      tx.date.year == year &&
      tx.date.month == month).toList();

  // Clasificar cada transacción por proximidad: ¿es pago de quincena (~15) o fin de mes (~último)?
  FinancialTransaction? midMonthPayment;
  FinancialTransaction? endMonthPayment;

  for (var tx in incomeTxs) {
    final distToMid = (tx.date.day - 15).abs();
    final distToEnd = (tx.date.day - lastDayOfMonth).abs();

    if (distToMid <= distToEnd) {
      // Más cerca del 15 → pago de quincena
      if (midMonthPayment == null ||
          (tx.date.day - 15).abs() < (midMonthPayment.date.day - 15).abs()) {
        midMonthPayment = tx;
      }
    } else {
      // Más cerca del último día → pago de fin de mes
      if (endMonthPayment == null ||
          (tx.date.day - lastDayOfMonth).abs() < (endMonthPayment.date.day - lastDayOfMonth).abs()) {
        endMonthPayment = tx;
      }
    }
  }

  // Caso 0: Sin pagos confirmados → split por defecto
  if (midMonthPayment == null && endMonthPayment == null) {
    return [
      DateRange(
        DateTime(year, month, 1),
        DateTime(year, month, 15, 23, 59, 59),
      ),
      DateRange(
        DateTime(year, month, 16),
        DateTime(year, month, lastDayOfMonth, 23, 59, 59),
      ),
    ];
  }

  // Caso 1: Solo pago de quincena confirmado
  if (midMonthPayment != null && endMonthPayment == null) {
    final col1Start = midMonthPayment.date.day.clamp(2, lastDayOfMonth);
    return [
      DateRange(
        DateTime(year, month, 1),
        DateTime(year, month, col1Start - 1, 23, 59, 59),
      ),
      DateRange(
        DateTime(year, month, col1Start),
        DateTime(year, month, lastDayOfMonth, 23, 59, 59),
      ),
    ];
  }

  // Caso 2: Solo pago de fin de mes confirmado (sin quincena)
  if (midMonthPayment == null && endMonthPayment != null) {
    final endDay = endMonthPayment.date.day;
    // El siguiente periodo de quincena es ~15 del mes siguiente
    final nextMidDate = DateTime(year, month + 1, 15, 23, 59, 59);
    return [
      DateRange(
        DateTime(year, month, 1),
        DateTime(year, month, endDay - 1, 23, 59, 59),
      ),
      DateRange(
        DateTime(year, month, endDay),
        nextMidDate,
      ),
    ];
  }

  // Caso 3: Ambos pagos confirmados → desplazar rangos
  // Periodo completado: [midDay, endDay-1]
  // Periodo activo (cruza mes): [endDay, ~15 del siguiente mes]
  final midDay = midMonthPayment!.date.day.clamp(2, lastDayOfMonth);
  final endDay = endMonthPayment!.date.day;
  final nextMidDate = DateTime(year, month + 1, 15, 23, 59, 59);

  return [
    DateRange(
      DateTime(year, month, midDay),
      DateTime(year, month, endDay - 1, 23, 59, 59),
    ),
    DateRange(
      DateTime(year, month, endDay),
      nextMidDate,
    ),
  ];
}

// Provider auxiliar para obtener todos los gastos fijos
final allFixedExpensesProvider = StreamProvider<List<Expense>>((ref) {
  return ref.watch(expenseDaoProvider).watchFixedExpenses();
});

// Provider para obtener las DEUDAS
final planningDebtsProvider = StreamProvider<List<Debt>>((ref) async* {
  final isar = await ref.watch(isarServiceProvider).db;
  yield* isar.debts.where().watch(fireImmediately: true);
});
