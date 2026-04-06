import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import '../../data/local_db/isar_db.dart';
import '../../data/models/exchange_rate.dart';
import '../../data/models/currency_settings.dart';

/// Servicio encargado de obtener, cachear y consultar tasas de cambio.
class ExchangeRateService {
  final IsarService _isarService;

  /// Duración del caché antes de intentar refrescar (por defecto 4 horas).
  final Duration cacheDuration;

  static const String _apiUrl = 'https://ve.dolarapi.com/v1/dolares';

  ExchangeRateService(
    this._isarService, {
    this.cacheDuration = const Duration(hours: 4),
  });

  // ---------------------------------------------------------------------------
  // Obtener la configuración de moneda (singleton)
  // ---------------------------------------------------------------------------

  /// Retorna la configuración de moneda actual, o crea una por defecto si no existe.
  Future<CurrencySettings> getCurrencySettings() async {
    final isar = await _isarService.db;
    final existing = await isar.currencySettings.get(1);
    if (existing != null) return existing;

    // Crear configuración por defecto
    final defaults = CurrencySettings();
    await isar.writeTxn(() async {
      await isar.currencySettings.put(defaults);
    });
    return defaults;
  }

  /// Guarda la configuración de moneda.
  Future<void> saveCurrencySettings(CurrencySettings settings) async {
    final isar = await _isarService.db;
    settings.id = 1; // Siempre singleton
    await isar.writeTxn(() async {
      await isar.currencySettings.put(settings);
    });
  }

  /// Stream que observa cambios en la configuración de moneda.
  Stream<CurrencySettings?> watchCurrencySettings() async* {
    final isar = await _isarService.db;
    // Asegurar que existe un registro
    await getCurrencySettings();
    yield* isar.currencySettings.watchObject(1, fireImmediately: true);
  }

  // ---------------------------------------------------------------------------
  // Obtención y caché de tasas de cambio
  // ---------------------------------------------------------------------------

  /// Obtiene la tasa de cambio actual. Intenta usar caché primero.
  /// Si el caché está vencido o vacío, hace fetch a la API.
  Future<ExchangeRate?> getCurrentRate() async {
    final cached = await _getLatestCachedRate();

    if (cached != null) {
      final age = DateTime.now().difference(cached.date);
      if (age < cacheDuration) {
        return cached;
      }
    }

    // Caché vencido o inexistente: intentar fetch
    final fetched = await fetchAndCacheRate();
    return fetched ?? cached; // Si fetch falla, devolver caché viejo
  }

  /// Fuerza un fetch desde la API y almacena el resultado en Isar.
  Future<ExchangeRate?> fetchAndCacheRate() async {
    try {
      debugPrint('ExchangeRateService: Fetching from $_apiUrl');
      final response = await http.get(Uri.parse(_apiUrl)).timeout(
        const Duration(seconds: 10),
      );

      debugPrint('ExchangeRateService: Status ${response.statusCode}, body: ${response.body.substring(0, response.body.length.clamp(0, 200))}');

      if (response.statusCode != 200) {
        debugPrint('ExchangeRateService: HTTP ${response.statusCode}');
        return null;
      }

      final decoded = json.decode(response.body);

      // Soportar tanto array (ve.dolarapi.com) como objeto (fallback)
      final List<dynamic> dataList;
      if (decoded is List) {
        dataList = decoded;
      } else if (decoded is Map<String, dynamic>) {
        // Si por alguna razón llega un objeto único, lo envolvemos en lista
        dataList = [decoded];
      } else {
        debugPrint('ExchangeRateService: Formato de respuesta inesperado');
        return null;
      }

      // Buscar la tasa oficial (BCV)
      final items = dataList.cast<Map<String, dynamic>>();
      final oficial = items.firstWhere(
        (item) => item['fuente'] == 'oficial',
        orElse: () => <String, dynamic>{},
      );

      if (oficial.isEmpty) {
        debugPrint('ExchangeRateService: No se encontró tasa oficial en ${items.length} items');
        debugPrint('ExchangeRateService: Items: ${items.map((e) => e['fuente'] ?? e['casa']).toList()}');
        return null;
      }

      // Usar 'promedio' (ve.dolarapi.com) con fallback a 'venta'
      final bcvRate = (oficial['promedio'] as num?)?.toDouble()
          ?? (oficial['venta'] as num?)?.toDouble();

      debugPrint('ExchangeRateService: Tasa obtenida = $bcvRate');

      if (bcvRate == null || bcvRate <= 0) {
        debugPrint('ExchangeRateService: Tasa inválida en respuesta');
        return null;
      }

      final rate = ExchangeRate()
        ..fromCurrency = 'USD'
        ..toCurrency = 'BS'
        ..rate = bcvRate
        ..date = DateTime.now()
        ..source = 'BCV';

      final isar = await _isarService.db;
      await isar.writeTxn(() async {
        // Limpiar tasas viejas antes de guardar la nueva
        await isar.exchangeRates.clear();
        await isar.exchangeRates.put(rate);
      });

      return rate;
    } catch (e) {
      debugPrint('ExchangeRateService: Error al obtener tasa: $e');
      return null;
    }
  }

  /// Retorna la tasa más reciente almacenada en Isar.
  Future<ExchangeRate?> _getLatestCachedRate() async {
    final isar = await _isarService.db;
    return await isar.exchangeRates
        .where()
        .sortByDateDesc()
        .findFirst();
  }

  /// Retorna la tasa de cambio más cercana a una fecha específica.
  /// Útil para consultas históricas.
  Future<ExchangeRate?> getRateForDate(DateTime date) async {
    final isar = await _isarService.db;

    // Buscar la tasa más cercana ANTES o en la fecha dada
    final rate = await isar.exchangeRates
        .filter()
        .dateLessThan(date.add(const Duration(days: 1)))
        .sortByDateDesc()
        .findFirst();

    return rate;
  }

  // ---------------------------------------------------------------------------
  // Conversión de montos
  // ---------------------------------------------------------------------------

  /// Convierte un monto de una moneda a otra usando la tasa proporcionada.
  /// [amount] - el monto a convertir.
  /// [fromCurrency] - moneda de origen (ej: "USD" o "BS").
  /// [toCurrency] - moneda destino.
  /// [rate] - tasa de cambio (BS por USD). Si es null, usa la tasa actual cacheada.
  Future<double?> convertAmount({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    double? rate,
  }) async {
    if (fromCurrency == toCurrency) return amount;

    double? exchangeRate = rate;
    if (exchangeRate == null) {
      final currentRate = await getCurrentRate();
      if (currentRate == null) return null;
      exchangeRate = currentRate.rate;
    }

    // La tasa siempre es BS por USD (ej: 36.59)
    if (fromCurrency == 'USD' && toCurrency == 'BS') {
      return amount * exchangeRate;
    } else if (fromCurrency == 'BS' && toCurrency == 'USD') {
      return amount / exchangeRate;
    }

    // Monedas no soportadas
    return null;
  }

  /// Convierte un monto a moneda de referencia dado su currencyCode.
  /// Si currencyCode es null o ya es la moneda de referencia, retorna el monto sin cambios.
  Future<double?> toReferenceCurrency({
    required double amount,
    String? currencyCode,
    double? rate,
  }) async {
    final settings = await getCurrencySettings();
    final refCurrency = settings.referenceCurrency;

    // Si no tiene moneda o ya es referencia, no convertir
    if (currencyCode == null || currencyCode == refCurrency) {
      return amount;
    }

    return convertAmount(
      amount: amount,
      fromCurrency: currencyCode,
      toCurrency: refCurrency,
      rate: rate,
    );
  }

  /// Convierte un monto a moneda local dado su currencyCode.
  Future<double?> toLocalCurrency({
    required double amount,
    String? currencyCode,
    double? rate,
  }) async {
    final settings = await getCurrencySettings();
    final localCurrency = settings.localCurrency;

    if (currencyCode == null || currencyCode == localCurrency) {
      return amount;
    }

    return convertAmount(
      amount: amount,
      fromCurrency: currencyCode,
      toCurrency: localCurrency,
      rate: rate,
    );
  }

  /// Calcula ambos montos (referencia y local) para una transacción.
  /// Retorna un record con ambos valores pre-calculados.
  Future<({double? referenceAmount, double? localAmount})>
      calculateBothAmounts({
    required double amount,
    required String? currencyCode,
    double? rate,
  }) async {
    final settings = await getCurrencySettings();
    final refCurrency = settings.referenceCurrency;
    final locCurrency = settings.localCurrency;

    final effectiveCurrency = currencyCode ?? refCurrency;

    double? referenceAmount;
    double? localAmount;

    if (effectiveCurrency == refCurrency) {
      referenceAmount = amount;
      localAmount = await convertAmount(
        amount: amount,
        fromCurrency: refCurrency,
        toCurrency: locCurrency,
        rate: rate,
      );
    } else if (effectiveCurrency == locCurrency) {
      localAmount = amount;
      referenceAmount = await convertAmount(
        amount: amount,
        fromCurrency: locCurrency,
        toCurrency: refCurrency,
        rate: rate,
      );
    }

    return (referenceAmount: referenceAmount, localAmount: localAmount);
  }
}
