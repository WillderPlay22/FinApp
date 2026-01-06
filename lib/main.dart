import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'package:isar/isar.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'config/theme/app_theme.dart';
import 'ui/home/home_screen.dart';
import 'data/local_db/isar_db.dart';
import 'logic/services/category_seeder.dart';
import 'logic/services/notification_service.dart'; 
import 'ui/income/modals/recurring_detail_modal.dart';
import 'data/models/recurring_movement.dart'; 

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);

  // 1. Iniciar Servicio de Notificaciones
  await NotificationService().init();

  final isarService = IsarService();
  final seeder = CategorySeeder(isarService);
  await seeder.seedDefaults();

  // 2. Programar notificaciones al iniciar (para recuperar alarmas si se apagó el cel)
  final isar = await isarService.db;
  final allIncomes = await isar.recurringMovements.where().findAll();
  await NotificationService().scheduleAllNotifications(allIncomes);

  // 🕵️‍♂️ --- INICIO DEL DIAGNÓSTICO --- 🕵️‍♂️
  print("\n🔵 ================= DIAGNÓSTICO DE NOTIFICACIONES =================");
  
  // A. Ver la hora exacta y zona horaria que detecta la app
  final now = tz.TZDateTime.now(tz.local);
  print("⌚ Hora actual del sistema (Timezone): $now");
  print("🌍 Zona Horaria detectada: ${tz.local.name}");

  // B. Consultar al sistema Android cuántas alarmas hay realmente
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final List<PendingNotificationRequest> pending = 
      await flutterLocalNotificationsPlugin.pendingNotificationRequests();
  
  if (pending.isEmpty) {
    print("❌ ALERTA: La lista de notificaciones pendientes está VACÍA.");
    print("   Posible causa: La lógica de fechas falló o Android bloqueó la programación.");
  } else {
    print("✅ ESTADO OK: Hay ${pending.length} notificaciones en cola:");
    for (var p in pending) {
      print("   ➡ ID: ${p.id} | Título: ${p.title} | Payload: ${p.payload}");
    }
  }
  print("🔵 ================= FIN DEL DIAGNÓSTICO ==========================\n");
  // -----------------------------------------------------------------------

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
    // Escuchar si tocan una notificación para abrir el modal
    NotificationService().selectNotificationStream.stream.listen((payload) {
      if (payload != null) _handleNotificationOpen(payload);
    });
  }

  Future<void> _handleNotificationOpen(String payload) async {
    try {
      final parts = payload.split('|');
      final incomeId = int.parse(parts[0]);
      final isar = await IsarService().db;
      final income = await isar.recurringMovements.get(incomeId);

      if (income != null && navigatorKey.currentContext != null) {
        showModalBottomSheet(
          context: navigatorKey.currentContext!,
          isScrollControlled: true,
          builder: (ctx) => RecurringDetailModal(movement: income),
        );
      }
    } catch (e) {
      print("Error abriendo notificación: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FinApp',
      navigatorKey: navigatorKey, 
      theme: AppTheme().getTheme(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
      home: const HomeScreen(),
    );
  }
}