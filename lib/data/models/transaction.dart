import 'package:isar/isar.dart';
import 'enums.dart';
import 'expense.dart';
import 'debt.dart';

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

  // --- VINCULACIÓN GASTOS (NUEVO) ---
  bool isRecurring = false;

  // Enlaza esta transacción al gasto fijo original que la generó.
  final relatedExpense = IsarLink<Expense>();

  // Enlaza esta transacción a la deuda original que la generó.
  final relatedDebt = IsarLink<Debt>();

  // Constructor vacío para la creación de instancias sin parámetros.
  FinancialTransaction();
}