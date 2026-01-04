import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
// 1. IMPORTANTE: Paquete de localizaciones para que el calendario no falle
import 'package:flutter_localizations/flutter_localizations.dart'; 

import 'config/theme/app_theme.dart';
import 'ui/home/home_screen.dart';
// 2. Importaciones de Base de Datos y Semillas
import 'data/local_db/isar_db.dart';
import 'logic/services/category_seeder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializamos formato de fecha
  await initializeDateFormatting('es', null);

  // 3. INICIO BASE DE DATOS Y CATEGORÍAS
  // Esto asegura que Isar arranque y se creen las categorías por defecto
  final isarService = IsarService();
  final seeder = CategorySeeder(isarService);
  await seeder.seedDefaults();
  // ------------------------------------

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FinApp',
      theme: AppTheme().getTheme(),
      
      // 4. CONFIGURACIÓN DE IDIOMA (Solución al Crash del Calendario)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español (Principal)
        Locale('en', 'US'), // Inglés (Respaldo)
      ],
      
      home: const HomeScreen(),
    );
  }
}