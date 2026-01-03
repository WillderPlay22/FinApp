import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart'; // 1. IMPORTANTE: Importar esto
import 'config/theme/app_theme.dart';
import 'ui/home/home_screen.dart';

// 2. Convertimos el main en asíncrono (Future<void> ... async)
Future<void> main() async {
  // Aseguramos que los widgets estén listos antes de cargar configuraciones
  WidgetsFlutterBinding.ensureInitialized();
  
  // 3. Inicializamos el formato de fechas para Español ('es')
  await initializeDateFormatting('es', null);

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
      home: const HomeScreen(),
    );
  }
}