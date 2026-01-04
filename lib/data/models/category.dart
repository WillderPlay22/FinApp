import 'package:isar/isar.dart';
import 'enums.dart'; 

part 'category.g.dart';

@collection
class Category {
  Id id = Isar.autoIncrement;

  late String name; 
  
  late int iconCode; 
  
  late int colorValue; 

  // CORRECCIÓN AQUÍ: Usamos 'name' en lugar de 'ordinal'
  // Esto permite guardar nulos sin problemas.
  @Enumerated(EnumType.name)
  Frequency? frequency; 

  bool isExpense; 

  Category({
    required this.name,
    required this.iconCode,
    required this.colorValue,
    this.frequency, 
    this.isExpense = true,
  });
  
  Category.empty() : isExpense = true;
}