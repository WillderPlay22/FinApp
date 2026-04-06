import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/currency_settings.dart';
import '../../data/models/exchange_rate.dart';
import '../services/exchange_rate_service.dart';
import 'database_providers.dart';

// ---------------------------------------------------------------------------
// 1. Proveedor del servicio de tasas de cambio
// ---------------------------------------------------------------------------

final exchangeRateServiceProvider = Provider<ExchangeRateService>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return ExchangeRateService(isarService);
});

// ---------------------------------------------------------------------------
// 2. Proveedor de la configuración de moneda (Stream reactivo)
// ---------------------------------------------------------------------------

final currencySettingsProvider = StreamProvider<CurrencySettings?>((ref) {
  final service = ref.watch(exchangeRateServiceProvider);
  return service.watchCurrencySettings();
});

// ---------------------------------------------------------------------------
// 3. Proveedor derivado: multi-moneda habilitado?
// ---------------------------------------------------------------------------

final isMultiCurrencyEnabledProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(currencySettingsProvider);
  return settingsAsync.whenOrNull(data: (s) => s?.isMultiCurrencyEnabled) ?? false;
});

// ---------------------------------------------------------------------------
// 4. Proveedor de la tasa de cambio actual (FutureProvider)
// ---------------------------------------------------------------------------

final currentExchangeRateProvider = FutureProvider<ExchangeRate?>((ref) async {
  final service = ref.watch(exchangeRateServiceProvider);
  return await service.getCurrentRate();
});

// ---------------------------------------------------------------------------
// 5. Proveedor del conversor de moneda
//    Expone métodos de conversión que usan la tasa actual.
// ---------------------------------------------------------------------------

final currencyConverterProvider = Provider<CurrencyConverter>((ref) {
  final service = ref.watch(exchangeRateServiceProvider);
  return CurrencyConverter(service);
});

/// Clase auxiliar que envuelve el servicio para ofrecer una API sencilla
/// de conversión desde los providers.
class CurrencyConverter {
  final ExchangeRateService _service;

  CurrencyConverter(this._service);

  /// Convierte un monto entre monedas usando la tasa actual.
  Future<double?> convert({
    required double amount,
    required String from,
    required String to,
    double? rate,
  }) {
    return _service.convertAmount(
      amount: amount,
      fromCurrency: from,
      toCurrency: to,
      rate: rate,
    );
  }

  /// Convierte a la moneda de referencia.
  Future<double?> toReference({
    required double amount,
    String? currencyCode,
    double? rate,
  }) {
    return _service.toReferenceCurrency(
      amount: amount,
      currencyCode: currencyCode,
      rate: rate,
    );
  }

  /// Convierte a la moneda local.
  Future<double?> toLocal({
    required double amount,
    String? currencyCode,
    double? rate,
  }) {
    return _service.toLocalCurrency(
      amount: amount,
      currencyCode: currencyCode,
      rate: rate,
    );
  }

  /// Calcula ambos montos (referencia y local) de una sola vez.
  Future<({double? referenceAmount, double? localAmount})> calculateBoth({
    required double amount,
    String? currencyCode,
    double? rate,
  }) {
    return _service.calculateBothAmounts(
      amount: amount,
      currencyCode: currencyCode,
      rate: rate,
    );
  }
}
