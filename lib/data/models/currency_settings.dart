import 'package:isar/isar.dart';

part 'currency_settings.g.dart';

/// Singleton collection: solo se almacena un registro con id = 1.
@collection
class CurrencySettings {
  Id id = 1; // Singleton: siempre ID fijo

  bool isMultiCurrencyEnabled = false;

  /// La moneda de referencia (por defecto USD).
  String referenceCurrency = 'USD';

  /// La moneda local (por defecto BS - Bolívares).
  String localCurrency = 'BS';

  CurrencySettings();
}
