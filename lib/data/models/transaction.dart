import 'package:isar/isar.dart';
import 'enums.dart';

part 'transaction.g.dart'; // Dará error rojo hasta el paso final

@collection
class FinancialTransaction {
  Id id = Isar.autoIncrement; // ID automático (1, 2, 3...)

  late double amount; // Cuánto dinero

  late String note; // Nota opcional (ej: "Hamburguesa")

  late DateTime date; // Fecha y hora exacta

  @Enumerated(EnumType.name)
  late TransactionType type; // ¿Entró o salió dinero?

  // Guardamos datos visuales de la categoría
  late String categoryName;   // Ej: "Comida"
  late int categoryIconCode;  // El código del icono para dibujarlo luego
  late int colorValue;        // El color de la categoría
}