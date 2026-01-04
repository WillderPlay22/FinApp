import 'package:isar/isar.dart';
import 'category.dart'; // Importamos la categoría que acabamos de crear

part 'expense.g.dart'; // Dará error temporalmente

@collection
class Expense {
  Id id = Isar.autoIncrement;

  late String title; // Ej: "Netflix"
  
  late double amount; // Ej: 15.00
  
  late DateTime date; // Fecha del gasto

  // ¿Es un gasto fijo heredado de la categoría? 
  bool isRecurring = false; 

  // RELACIÓN: Un gasto pertenece a una Categoría
  final category = IsarLink<Category>();

  Expense({
    required this.title,
    required this.amount,
    required this.date,
    this.isRecurring = false,
  });
}