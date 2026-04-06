import 'package:isar/isar.dart';
import '../local_db/isar_db.dart';
import '../models/transaction.dart';
import '../models/enums.dart';
import '../models/exchange_rate.dart';
import '../models/currency_settings.dart';

class TransactionDao {
  final IsarService isarService;

  TransactionDao(this.isarService);

  /// Obtiene la tasa de cambio más reciente desde Isar.
  Future<double?> _getLatestRate() async {
    final isar = await isarService.db;
    final settings = await isar.currencySettings.get(1);
    if (settings == null || !settings.isMultiCurrencyEnabled) return null;
    final rate = await isar.exchangeRates.where().sortByDateDesc().findFirst();
    return rate?.rate;
  }

  // 1. Guardar transacción (Sirve para Ingresos y Gastos Extras)
  /// [currencyCode], [exchangeRate] son opcionales para multi-moneda.
  Future<void> addTransaction(
    FinancialTransaction transaction, {
    String? currencyCode,
    double? exchangeRate,
    PaymentMode? paymentMode,
    double? fixedReferencePortion,
    double? fixedLocalPortion,
  }) async {
    // Aplicar datos de moneda si se proporcionan
    if (currencyCode != null) {
      transaction.currencyCode = currencyCode;
    }
    if (exchangeRate != null) {
      transaction.exchangeRateAtTime = exchangeRate;

      // Pre-calcular montos en ambas monedas
      final effectiveCurrency = transaction.currencyCode;
      if (effectiveCurrency == 'USD') {
        transaction.amountInReferenceCurrency = transaction.amount;
        transaction.amountInLocalCurrency = transaction.amount * exchangeRate;
      } else if (effectiveCurrency == 'BS') {
        transaction.amountInLocalCurrency = transaction.amount;
        transaction.amountInReferenceCurrency = transaction.amount / exchangeRate;
      }
    }

    // Aplicar datos de pago dividido si se proporcionan
    if (paymentMode != null) {
      transaction.paymentMode = paymentMode;
      transaction.fixedReferencePortion = fixedReferencePortion;
      transaction.fixedLocalPortion = fixedLocalPortion;

      if (paymentMode == PaymentMode.allReference) {
        transaction.amount = fixedReferencePortion ?? transaction.amount;
        transaction.currencyCode = 'USD';
        transaction.amountInReferenceCurrency = fixedReferencePortion;
        transaction.amountInLocalCurrency = (fixedReferencePortion ?? 0) * (exchangeRate ?? 0);
      } else if (paymentMode == PaymentMode.allLocal) {
        transaction.amount = fixedLocalPortion ?? transaction.amount;
        transaction.currencyCode = 'BS';
        transaction.amountInLocalCurrency = fixedLocalPortion;
        transaction.amountInReferenceCurrency = exchangeRate != null && exchangeRate > 0
            ? (fixedLocalPortion ?? 0) / exchangeRate
            : null;
      } else if (paymentMode == PaymentMode.mixed) {
        final usdPart = fixedReferencePortion ?? 0.0;
        final bsPart = fixedLocalPortion ?? 0.0;
        transaction.currencyCode = 'MIXED';
        transaction.amountInReferenceCurrency = exchangeRate != null && exchangeRate > 0
            ? usdPart + (bsPart / exchangeRate)
            : usdPart;
        transaction.amountInLocalCurrency = exchangeRate != null
            ? (usdPart * exchangeRate) + bsPart
            : bsPart;
        transaction.amount = transaction.amountInReferenceCurrency!;
      }
    }

    final isar = await isarService.db;
    await isar.writeTxn(() async {
      await isar.financialTransactions.put(transaction);
    });
  }

  // 2. Verificar si ya existe un pago (Para lógica de recurrentes)
  Future<bool> isPaymentMade({
    required int recurringId,
    required DateTime start,
    required DateTime end
  }) async {
    final isar = await isarService.db;

    final count = await isar.financialTransactions
        .filter()
        .parentRecurringIdEqualTo(recurringId)
        .and()
        .dateBetween(start, end)
        .count();

    return count > 0;
  }

  // ✅ 3. NUEVO: CONTAR PAGOS (Necesario para la corrección quincenal)
  Future<int> countPayments({
    required int recurringId,
    required DateTime start,
    required DateTime end
  }) async {
    final isar = await isarService.db;

    return await isar.financialTransactions
        .filter()
        .parentRecurringIdEqualTo(recurringId)
        .and()
        .dateBetween(start, end)
        .count();
  }

  // 4. Obtener último pago confirmado de un ingreso recurrente
  Future<FinancialTransaction?> getLastConfirmedPayment(int recurringId) async {
    final isar = await isarService.db;
    return await isar.financialTransactions
        .filter()
        .parentRecurringIdEqualTo(recurringId)
        .and()
        .typeEqualTo(TransactionType.income)
        .sortByDateDesc()
        .findFirst();
  }

  // 5. Leer SOLO INGRESOS
  Stream<List<FinancialTransaction>> watchIncomeTransactions() async* {
    final isar = await isarService.db;
    yield* isar.financialTransactions
        .filter()
        .typeEqualTo(TransactionType.income)
        .sortByDateDesc()
        .watch(fireImmediately: true);
  }

  // 5. Total Ingresos Mes
  Stream<double> watchTotalIncomeThisMonth(DateTime now) async* {
    final isar = await isarService.db;
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final query = isar.financialTransactions
        .filter()
        .typeEqualTo(TransactionType.income)
        .dateBetween(startOfMonth, endOfMonth)
        .build();

    await for (final transactions in query.watch(fireImmediately: true)) {
      if (transactions.isEmpty) {
        yield 0.0;
        continue;
      }
      final rate = await _getLatestRate();
      yield transactions.fold(0.0, (sum, item) => sum + item.referenceAmountWithRate(rate));
    }
  }

  // 6. BORRAR TRANSACCIÓN (Para el Swipe)
  Future<void> deleteTransaction(int id) async {
    final isar = await isarService.db;
    await isar.writeTxn(() async {
      await isar.financialTransactions.delete(id);
    });
  }
}
