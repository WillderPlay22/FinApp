import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'package:isar/isar.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'config/theme/app_theme.dart';
import 'ui/home/home_screen.dart';
// ✅ IMPORTAMOS LAS PANTALLAS Y MODALES NECESARIOS PARA LA NAVEGACIÓN
import 'ui/expenses/expenses_screen.dart';
import 'ui/income/income_screen.dart';
import 'logic/providers/time_provider.dart';
import 'data/local_db/isar_db.dart';
import 'logic/services/category_seeder.dart';
import 'logic/services/notification_service.dart'; 
import 'ui/income/modals/recurring_detail_modal.dart';
import 'data/models/recurring_movement.dart'; 
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

// --- WIDGET CONTENEDOR CON LA BARRA DE NAVEGACIÓN ---

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;

  // Pantalla de Ahorro (Placeholder)
  static final Widget _savingsScreen = Scaffold(
    appBar: AppBar(title: const Text("Ahorro")),
    body: const Center(child: Icon(FontAwesomeIcons.piggyBank, size: 60, color: Colors.pinkAccent)),
  );

  // Lista de las 4 pantallas principales
  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),     // La nueva pantalla de inicio
    const ExpensesScreen(), // Tu pantalla de gastos existente
    const IncomeScreen(),   // Tu pantalla de ingresos existente
    _savingsScreen,
  ];

  @override
  void initState() {
    super.initState();
    // Restauramos el observador del ciclo de vida de la app
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  // El observador que invalida la fecha cuando la app vuelve a primer plano
  late final WidgetsBindingObserver _lifecycleObserver =
      LifecycleObserver(ref: ref);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Gastos'),
          BottomNavigationBarItem(icon: Icon(Icons.monetization_on_outlined), activeIcon: Icon(Icons.monetization_on), label: 'Ingresos'),
          BottomNavigationBarItem(icon: Icon(Icons.savings_outlined), activeIcon: Icon(Icons.savings), label: 'Ahorro'),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed, // Mantiene los 4 items visibles
        showUnselectedLabels: true,
      ),
    );
  }
}

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
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
      home: const AppShell(), // La app ahora empieza en el AppShell
    );
  }
}

// Clase auxiliar para manejar el ciclo de vida de la app
class LifecycleObserver with WidgetsBindingObserver {
  final WidgetRef ref;
  LifecycleObserver({required this.ref});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Cuando la app vuelve al primer plano, invalidamos el proveedor de tiempo.
      // Esto fuerza a todos los widgets que lo observan a reconstruirse con la
      // fecha y hora actualizadas, solucionando el problema de los ciclos.
      ref.invalidate(nowProvider);
    }
  }
}