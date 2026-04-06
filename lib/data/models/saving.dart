import 'package:isar/isar.dart';
import 'enums.dart';

part 'saving.g.dart';

@collection
class Saving {
  Id id = Isar.autoIncrement;

  late String name;

  @enumerated
  late SavingType type; // Meta vs Fondo

  double? targetAmount; // Solo para Metas
  double currentAmount = 0.0;

  @enumerated
  late SavingMethod method;
  double? fixedAmount;
  double? percentage; // 0.0 - 100.0

  int colorValue = 0xFFE91E63; // Pink por defecto
  int iconCode = 0xf555; // Piggy Bank

  // --- MULTI-MONEDA ---
  /// Código de moneda de los montos (null = moneda de referencia para retrocompatibilidad).
  String? currencyCode;
}