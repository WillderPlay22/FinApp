import 'package:isar/isar.dart';
import 'enums.dart';

part 'recurring_movement.g.dart';

@collection
class RecurringMovement {
  Id id = Isar.autoIncrement;

  late String title; 

  @Enumerated(EnumType.name)
  late TransactionType type; 

  @Enumerated(EnumType.name)
  late Frequency frequency; 

  // --- LÓGICA DE FECHAS Y MONTOS ---
  // Ej Quincenal: [15, -1]
  List<int>? paymentDays; 

  // Ej Quincenal: [1200.00, 1500.00]
  List<double>? paymentAmounts;

  // --- LÓGICA PARA INGRESO DIARIO (Promedios) ---
  bool isVariableDaily = false;
  double accumulatedAmount = 0; 
  int totalEntries = 0;         

  // --- LÓGICA DE DEUDAS / PROYECCIÓN ---
  late DateTime nextPaymentDate; 
  int? remainingInstallments; 
}