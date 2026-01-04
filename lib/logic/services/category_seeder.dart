import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../data/local_db/isar_db.dart';
import '../../data/models/category.dart';
// 👇 ESTA ES LA LÍNEA QUE FALTA PARA ARREGLAR EL ERROR ROJO
import '../../data/models/enums.dart';

class CategorySeeder {
  final IsarService isarService;

  CategorySeeder(this.isarService);

  Future<void> seedDefaults() async {
    final isar = await isarService.db;
    
    // 1. Verificar si ya existen categorías
    final count = await isar.categorys.count();
    
    if (count > 0) return; 

    // 2. Definir categorías base
    final defaultCategories = [
      // Frecuencia mensual por defecto para los fijos
      Category(name: "Comida", iconCode: FontAwesomeIcons.burger.codePoint, colorValue: 0xFFFFA726, frequency: Frequency.monthly),
      Category(name: "Transporte", iconCode: FontAwesomeIcons.bus.codePoint, colorValue: 0xFF42A5F5, frequency: Frequency.monthly),
      Category(name: "Casa", iconCode: FontAwesomeIcons.house.codePoint, colorValue: 0xFF8D6E63, frequency: Frequency.monthly),
      Category(name: "Servicios", iconCode: FontAwesomeIcons.bolt.codePoint, colorValue: 0xFFFDD835, frequency: Frequency.monthly),
      
      // Gastos variables
      Category(name: "Salud", iconCode: FontAwesomeIcons.heartPulse.codePoint, colorValue: 0xFFEF5350, frequency: Frequency.monthly),
      Category(name: "Compras", iconCode: FontAwesomeIcons.bagShopping.codePoint, colorValue: 0xFFAB47BC, frequency: Frequency.monthly),
      Category(name: "Ocio", iconCode: FontAwesomeIcons.gamepad.codePoint, colorValue: 0xFF5C6BC0, frequency: Frequency.monthly),
      Category(name: "Educación", iconCode: FontAwesomeIcons.graduationCap.codePoint, colorValue: 0xFF26A69A, frequency: Frequency.monthly),
      Category(name: "Otros", iconCode: FontAwesomeIcons.shapes.codePoint, colorValue: 0xFFBDBDBD, frequency: Frequency.monthly),
    ];

    // 3. Guardar en BD
    await isar.writeTxn(() async {
      await isar.categorys.putAll(defaultCategories);
    });
    
    debugPrint("🌱 Categorías sembradas exitosamente");
  }
}