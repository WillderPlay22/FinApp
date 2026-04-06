import 'package:isar/isar.dart';

part 'exchange_rate.g.dart';

@collection
class ExchangeRate {
  Id id = Isar.autoIncrement;

  late String fromCurrency; // e.g. "USD"
  late String toCurrency;   // e.g. "BS"
  late double rate;          // e.g. 36.59 (BS per USD)

  @Index()
  late DateTime date;

  late String source; // e.g. "BCV" or "dolarapi.com"

  ExchangeRate();
}
