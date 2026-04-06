import 'package:isar/isar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../local_db/isar_db.dart';
import '../models/recurring_movement.dart';
import '../models/transaction.dart';
import '../models/enums.dart';
import '../models/exchange_rate.dart';
import '../models/currency_settings.dart';

class NextPaymentInfo {
  final DateTime expectedDate;
  final double amount;
  final String label;

  NextPaymentInfo({
    required this.expectedDate,
    required this.amount,
    required this.label,
  });
}

class RecurringDao {
  final IsarService isarService;

  RecurringDao(this.isarService);

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
    final query = isar.recurringMovements
        .filter()
        .typeEqualTo(TransactionType.income)
        .build();

    await for (final movements in query.watch(fireImmediately: true)) {
      final rate = await _getLatestRate();
      double totalProjection = 0;
      for (var movement in movements) {
        // Sumamos los montos configurados en la lista (ej: [100, 150] = 250)
        double cycleSum = (movement.paymentAmounts ?? []).fold(0.0, (sum, val) => sum + val);

        switch (movement.frequency) {
          case Frequency.daily:
            totalProjection += _toReference(cycleSum * 30, movement.currencyCode, rate);
            break;
          case Frequency.weekly:
            totalProjection += _toReference(cycleSum * 4, movement.currencyCode, rate);
            break;
          case Frequency.biweekly:
            totalProjection += _toReference(cycleSum, movement.currencyCode, rate);
            break;
          case Frequency.monthly:
            totalProjection += _toReference(cycleSum, movement.currencyCode, rate);
            break;
          default:
            totalProjection += _toReference(cycleSum, movement.currencyCode, rate);
            break;
        }
      }
      yield totalProjection;
    }
  }

  // 4. Obtener todos (Para Notificaciones)
  Future<List<RecurringMovement>> getAllRecurringMovements() async {
    final isar = await isarService.db;
    return await isar.recurringMovements.where().findAll();
  }

  // 5. Próximo pago a confirmar
  Stream<NextPaymentInfo> watchNextPayment(RecurringMovement movement) async* {
    final isar = await isarService.db;

    final query = isar.financialTransactions
        .filter()
        .parentRecurringIdEqualTo(movement.id)
        .and()
        .typeEqualTo(TransactionType.income)
        .build();

    await for (final _ in query.watch(fireImmediately: true)) {
      // Obtener último pago confirmado
      final lastTx = await isar.financialTransactions
          .filter()
          .parentRecurringIdEqualTo(movement.id)
          .and()
          .typeEqualTo(TransactionType.income)
          .sortByDateDesc()
          .findFirst();

      yield _calculateNextPayment(movement, lastTx?.date);
    }
  }

  NextPaymentInfo _calculateNextPayment(RecurringMovement movement, DateTime? lastPaymentDate) {
    final freq = movement.frequency;
    final amounts = movement.paymentAmounts ?? [];
    final createdAt = movement.createdAt ?? DateTime.now();

    switch (freq) {
      case Frequency.biweekly:
        return _nextBiweekly(movement, lastPaymentDate, amounts, createdAt);
      case Frequency.monthly:
        return _nextMonthly(movement, lastPaymentDate, amounts, createdAt);
      case Frequency.weekly:
        return _nextWeekly(movement, lastPaymentDate, amounts, createdAt);
      case Frequency.daily:
        return _nextDaily(amounts, createdAt, lastPaymentDate);
      default:
        return _nextMonthly(movement, lastPaymentDate, amounts, createdAt);
    }
  }

  NextPaymentInfo _nextBiweekly(RecurringMovement movement, DateTime? lastDate, List<double> amounts, DateTime createdAt) {
    final amount15 = amounts.isNotEmpty ? amounts[0] : 0.0;
    final amountLast = amounts.length > 1 ? amounts[1] : amount15;

    if (lastDate == null) {
      // Primer pago: próximo día de pago desde createdAt
      if (createdAt.day <= 15) {
        return NextPaymentInfo(
          expectedDate: DateTime(createdAt.year, createdAt.month, 15),
          amount: amount15,
          label: "Quincena (Día 15)",
        );
      } else {
        final lastDay = DateTime(createdAt.year, createdAt.month + 1, 0).day;
        return NextPaymentInfo(
          expectedDate: DateTime(createdAt.year, createdAt.month, lastDay),
          amount: amountLast,
          label: "Fin de Mes (Día $lastDay)",
        );
      }
    }

    // Determinar cuál fue el último pago y calcular el siguiente
    if (lastDate.day <= 15) {
      // Último fue el 15 → próximo es fin de mes del mismo mes
      final lastDay = DateTime(lastDate.year, lastDate.month + 1, 0).day;
      return NextPaymentInfo(
        expectedDate: DateTime(lastDate.year, lastDate.month, lastDay),
        amount: amountLast,
        label: "Fin de Mes (Día $lastDay)",
      );
    } else {
      // Último fue fin de mes → próximo es 15 del mes siguiente
      final nextMonth = lastDate.month + 1;
      final nextYear = lastDate.year + (nextMonth > 12 ? 1 : 0);
      final adjustedMonth = nextMonth > 12 ? nextMonth - 12 : nextMonth;
      return NextPaymentInfo(
        expectedDate: DateTime(nextYear, adjustedMonth, 15),
        amount: amount15,
        label: "Quincena (Día 15)",
      );
    }
  }

  NextPaymentInfo _nextMonthly(RecurringMovement movement, DateTime? lastDate, List<double> amounts, DateTime createdAt) {
    final amount = amounts.isNotEmpty ? amounts[0] : 0.0;
    final configDay = (movement.paymentDays?.isNotEmpty == true) ? movement.paymentDays![0] : 1;

    if (lastDate == null) {
      // Primer pago desde createdAt
      int year = createdAt.year;
      int month = createdAt.month;
      if (createdAt.day > configDay) {
        month += 1;
        if (month > 12) { month = 1; year += 1; }
      }
      final lastDayOfMonth = DateTime(year, month + 1, 0).day;
      final actualDay = configDay > lastDayOfMonth ? lastDayOfMonth : configDay;
      return NextPaymentInfo(
        expectedDate: DateTime(year, month, actualDay),
        amount: amount,
        label: "Día $actualDay",
      );
    }

    // Mes siguiente al último pago
    int nextMonth = lastDate.month + 1;
    int nextYear = lastDate.year;
    if (nextMonth > 12) { nextMonth = 1; nextYear += 1; }
    final lastDayOfMonth = DateTime(nextYear, nextMonth + 1, 0).day;
    final actualDay = configDay > lastDayOfMonth ? lastDayOfMonth : configDay;
    return NextPaymentInfo(
      expectedDate: DateTime(nextYear, nextMonth, actualDay),
      amount: amount,
      label: "Día $actualDay",
    );
  }

  NextPaymentInfo _nextWeekly(RecurringMovement movement, DateTime? lastDate, List<double> amounts, DateTime createdAt) {
    final amount = amounts.isNotEmpty ? amounts[0] : 0.0;
    final configDay = (movement.paymentDays?.isNotEmpty == true) ? movement.paymentDays![0] : 1;

    if (lastDate == null) {
      // Primer pago: próxima ocurrencia del día de la semana desde createdAt
      int daysUntil = configDay - createdAt.weekday;
      if (daysUntil < 0) daysUntil += 7;
      final nextDate = createdAt.add(Duration(days: daysUntil));
      return NextPaymentInfo(
        expectedDate: nextDate,
        amount: amount,
        label: _getDayName(configDay),
      );
    }

    // +7 días desde el último pago
    final nextDate = lastDate.add(const Duration(days: 7));
    return NextPaymentInfo(
      expectedDate: nextDate,
      amount: amount,
      label: _getDayName(configDay),
    );
  }

  NextPaymentInfo _nextDaily(List<double> amounts, DateTime createdAt, DateTime? lastDate) {
    final amount = amounts.isNotEmpty ? amounts[0] : 0.0;
    final now = DateTime.now();

    if (lastDate == null) {
      final date = createdAt.isBefore(now) ? now : createdAt;
      return NextPaymentInfo(
        expectedDate: DateTime(date.year, date.month, date.day),
        amount: amount,
        label: "Hoy",
      );
    }

    // Día siguiente al último pago, o hoy si ya pasó
    final nextDay = DateTime(lastDate.year, lastDate.month, lastDate.day + 1);
    final date = nextDay.isBefore(now) ? now : nextDay;
    return NextPaymentInfo(
      expectedDate: DateTime(date.year, date.month, date.day),
      amount: amount,
      label: "Hoy",
    );
  }

  String _getDayName(int weekday) {
    const days = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"];
    if (weekday >= 1 && weekday <= 7) return days[weekday - 1];
    return "Día $weekday";
  }

  // 6. Marcar como cobrado
  /// [exchangeRate] y [currencyCode] son opcionales para multi-moneda.
  Future<void> markAsCollected(
    RecurringMovement movement, {
    double? customAmount,
    double? exchangeRate,
    String? currencyCode,
    PaymentMode? paymentMode,
    double? fixedReferencePortion,
    double? fixedLocalPortion,
  }) async {
    final isar = await isarService.db;
    final now = DateTime.now();
    double baseAmount = customAmount ?? (movement.paymentAmounts?.isNotEmpty == true ? movement.paymentAmounts!.first : 0.0);
    final effectiveCurrency = currencyCode ?? movement.currencyCode;

    final newTx = FinancialTransaction()
      ..amount = baseAmount
      ..note = movement.title
      ..date = now
      ..type = TransactionType.income
      ..categoryName = "Ingreso Fijo"
      ..categoryIconCode = FontAwesomeIcons.moneyBillWave.codePoint
      ..colorValue = 0xFF4CAF50
      ..parentRecurringId = movement.id
      ..currencyCode = effectiveCurrency
      ..exchangeRateAtTime = exchangeRate;

    // Pre-calcular montos en ambas monedas si hay tasa
    if (exchangeRate != null && effectiveCurrency != null) {
      if (effectiveCurrency == 'USD') {
        newTx.amountInReferenceCurrency = baseAmount;
        newTx.amountInLocalCurrency = baseAmount * exchangeRate;
      } else if (effectiveCurrency == 'BS') {
        newTx.amountInLocalCurrency = baseAmount;
        newTx.amountInReferenceCurrency = baseAmount / exchangeRate;
      }
    }

    // Aplicar datos de pago dividido si se proporcionan
    if (paymentMode != null) {
      newTx.paymentMode = paymentMode;
      newTx.fixedReferencePortion = fixedReferencePortion;
      newTx.fixedLocalPortion = fixedLocalPortion;

      if (paymentMode == PaymentMode.allReference) {
        newTx.amount = fixedReferencePortion ?? baseAmount;
        newTx.currencyCode = 'USD';
        newTx.amountInReferenceCurrency = fixedReferencePortion;
        newTx.amountInLocalCurrency = (fixedReferencePortion ?? 0) * (exchangeRate ?? 0);
      } else if (paymentMode == PaymentMode.allLocal) {
        newTx.amount = fixedLocalPortion ?? baseAmount;
        newTx.currencyCode = 'BS';
        newTx.amountInLocalCurrency = fixedLocalPortion;
        newTx.amountInReferenceCurrency = exchangeRate != null && exchangeRate > 0
            ? (fixedLocalPortion ?? 0) / exchangeRate
            : null;
      } else if (paymentMode == PaymentMode.mixed) {
        final usdPart = fixedReferencePortion ?? 0.0;
        final bsPart = fixedLocalPortion ?? 0.0;
        newTx.currencyCode = 'MIXED';
        newTx.amountInReferenceCurrency = exchangeRate != null && exchangeRate > 0
            ? usdPart + (bsPart / exchangeRate)
            : usdPart;
        newTx.amountInLocalCurrency = exchangeRate != null
            ? (usdPart * exchangeRate) + bsPart
            : bsPart;
        newTx.amount = newTx.amountInReferenceCurrency!;
      }
    }

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