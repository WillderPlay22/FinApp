import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/theme/app_theme.dart';
import 'logic/providers/theme_provider.dart';
import 'ui/home/home_screen.dart';
import 'ui/planning/planning_screen.dart';
import 'ui/settings/settings_screen.dart';
import 'ui/widgets/floating_nav_bar.dart';
import 'logic/providers/time_provider.dart';
import 'data/local_db/isar_db.dart';
import 'logic/services/category_seeder.dart';
import 'logic/services/notification_service.dart';
import 'ui/income/modals/recurring_detail_modal.dart';
import 'data/models/recurring_movement.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);

  // 1. Iniciar SharedPreferences para el tema
  final sharedPreferences = await SharedPreferences.getInstance();

  // 2. Iniciar Servicio de Notificaciones
  await NotificationService().init();

  final isarService = IsarService();
  final seeder = CategorySeeder(isarService);
  await seeder.seedDefaults();

  // 3. Programar notificaciones al iniciar (para recuperar alarmas si se apagó el cel)
  final isar = await isarService.db;
  final allIncomes = await isar.recurringMovements.where().findAll();
  await NotificationService().scheduleAllNotifications(allIncomes);

  runApp(
    ProviderScope(
      overrides: [
        // Sobrescribimos el provider de SharedPreferences con la instancia real
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MainApp(),
    ),
  );
}

// --- WIDGET CONTENEDOR CON LA BARRA DE NAVEGACIÓN ---

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const PlanningScreen(),
    const SettingsScreen(),
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
      extendBody: true,
      body: _SlideNavStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: FloatingNavBar(
        selectedIndex: _selectedIndex,
        onItemTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

// ── Slide lateral entre pestañas del nav bar ──────────────────────────────

class _SlideNavStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const _SlideNavStack({required this.index, required this.children});

  @override
  State<_SlideNavStack> createState() => _SlideNavStackState();
}

class _SlideNavStackState extends State<_SlideNavStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  int _prevIndex = 0;
  int _currIndex = 0;
  bool _isSliding = false;
  bool _forward = true;

  @override
  void initState() {
    super.initState();
    _currIndex = widget.index;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _ctrl.reset();
        if (mounted) setState(() => _isSliding = false);
      }
    });
  }

  @override
  void didUpdateWidget(_SlideNavStack old) {
    super.didUpdateWidget(old);
    if (widget.index != _currIndex) {
      if (_isSliding) {
        _ctrl.stop();
        _ctrl.reset();
      }
      _forward = widget.index > _currIndex;
      _prevIndex = _currIndex;
      _currIndex = widget.index;
      setState(() => _isSliding = true);
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final t = _anim.value;
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: List.generate(widget.children.length, (i) {
            final child = widget.children[i];

            if (!_isSliding) {
              if (i == _currIndex) return child;
              return Offstage(
                child: TickerMode(enabled: false, child: child),
              );
            }

            if (i == _prevIndex) {
              final dx = _forward ? -t : t;
              return FractionalTranslation(
                translation: Offset(dx, 0),
                child: child,
              );
            }
            if (i == _currIndex) {
              final dx = _forward ? 1.0 - t : -(1.0 - t);
              return FractionalTranslation(
                translation: Offset(dx, 0),
                child: child,
              );
            }

            return Offstage(
              child: TickerMode(enabled: false, child: child),
            );
          }),
        );
      },
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
    // Se captura el contexto ANTES de cualquier 'await' para evitar advertencias del linter.
    final context = navigatorKey.currentContext;
    if (context == null) return;

    try {
      final parts = payload.split('|');
      final incomeId = int.parse(parts[0]);
      final isar = await IsarService().db;
      final income = await isar.recurringMovements.get(incomeId);

      // Se comprueba si el widget sigue "montado" DESPUÉS del 'await'.
      if (income != null && context.mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (ctx) => RecurringDetailModal(movement: income),
        );
      }
    } catch (e) {
      debugPrint("Error abriendo notificación: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Observamos el estado completo del tema (modo + paleta)
    final themeState = ref.watch(themeNotifierProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FinApp',
      navigatorKey: navigatorKey,

      // Temas claro y oscuro con la paleta seleccionada
      theme: AppTheme.lightTheme(themeState.palette),
      darkTheme: AppTheme.darkTheme(themeState.palette),
      themeMode: themeMode,

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
      home: const AppShell(),
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
      ref.invalidate(nowProvider);
    }
  }
}
