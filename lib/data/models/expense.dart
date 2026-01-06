import 'package:isar/isar.dart';
import 'category.dart';
import 'enums.dart'; // Importamos el enum Frequency

part 'expense.g.dart';

@collection
class Expense {
  Id id = Isar.autoIncrement;

  late String title;
  
  late double amount; 
  
  late DateTime date; 

  bool isRecurring = false; 

  // ✅ NUEVO: Frecuencia para la proyección
  @Enumerated(EnumType.name)
  late Frequency frequency;

  final category = IsarLink<Category>();

  Expense({
    required this.title,
    required this.amount,
    required this.date,
    this.isRecurring = false,
    this.frequency = Frequency.monthly, // Por defecto mensual
  });
}