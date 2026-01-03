import 'package:isar/isar.dart';
import 'enums.dart';

part 'recurring_movement.g.dart';

@collection
class RecurringMovement {
  Id id = Isar.autoIncrement;

  late String title; // Ej: "Sueldo", "Alquiler"

  @Enumerated(EnumType.name)
  late TransactionType type; // ¿Ingreso o Gasto?

  @Enumerated(EnumType.name)
  late Frequency frequency; // Diario, Semanal, Quincenal, Mensual

  // --- LÓGICA DE FECHAS Y MONTOS ---
  
  // Lista de días en los que ocurre el pago.
  // - Para Semanal: 1=Lunes, 7=Domingo.
  // - Para Quincenal/Mensual: 1 al 31. (-1 representa "Último día del mes").
  // Ej Quincenal: [15, -1]
  List<int>? paymentDays; 

  // Lista de montos correspondientes a cada día de arriba.
  // Ej Quincenal: [1200.00, 1500.00] (El 15 cobro 1200, el último 1500)
  List<double>? paymentAmounts;

  // --- LÓGICA PARA INGRESO DIARIO (Promedios) ---
  
  // ¿Es un ingreso diario variable? (Ej: Taxista, Tienda)
  bool isVariableDaily = false;
  
  // Para calcular el promedio automático:
  double accumulatedAmount = 0; // Suma total histórica
  int totalEntries = 0;         // Cuántas veces se ha registrado

  // --- LÓGICA DE DEUDAS / PROYECCIÓN ---
  
  late DateTime nextPaymentDate; // Próxima fecha calculada
  int? remainingInstallments; // Para deudas a crédito
}