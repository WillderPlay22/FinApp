import 'package:isar/isar.dart';
import 'enums.dart';

part 'transaction.g.dart'; 

@collection
class FinancialTransaction {
  Id id = Isar.autoIncrement; 

  late double amount; 

  late String note; 

  // Agregamos @Index() aquí para que filtrar por mes/año sea ultra rápido
  @Index()
  late DateTime date; 

  @Enumerated(EnumType.name)
  late TransactionType type; 

  // --- DATOS VISUALES ---
  late String categoryName;   
  late int categoryIconCode;  
  late int colorValue;        

  // --- VINCULACIÓN (NUEVO) ---
  // Si este campo tiene valor, significa que esta transacción
  // nació de un Ingreso Fijo (RecurringMovement).
  // Si es NULL, es un ingreso/gasto manual (Extra).
  @Index()
  int? parentRecurringId;
}