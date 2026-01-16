import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/enums.dart';
import '../../data/models/expense.dart';
import '../../data/models/debt.dart';
import '../../data/models/recurring_movement.dart';
import '../../data/models/transaction.dart';
import '../../date_utils.dart';
import '../../logic/providers/database_providers.dart';
import '../../logic/providers/time_provider.dart';

// Importamos las pantallas de módulos para reutilizar sus providers
import '../expenses/expenses_screen.dart';
import '../income/income_screen.dart';
import '../shared/icon_mapper.dart';

// --- PROVIDERS LOCALES PARA EL HOME ---

// Estado de Pagos Fijos (Pagados vs Totales en el mes actual)
final fixedPaymentsStatusProvider = StreamProvider<({int paid, int total})>((ref) async* {
  final expenseDao = ref.watch(expenseDaoProvider);
  final now = ref.watch(nowProvider);
  final range = getCycleDateRange(now, Frequency.monthly);
  final isar = await expenseDao.isarService.db;

  // Observamos las transacciones de tipo gasto que sean recurrentes (fijas) en el rango de fechas
  final query = isar.financialTransactions
      .filter()
      .typeEqualTo(TransactionType.expense)
      .isRecurringEqualTo(true)
      .dateBetween(range.start, range.end)
      .build();

  // Cada vez que cambien las transacciones, recalculamos
  await for (final transactions in query.watch(fireImmediately: true)) {
    // Obtenemos la lista total de gastos fijos activos
    final fixedExpenses = await isar.expenses.filter().isRecurringEqualTo(true).findAll();
    final total = fixedExpenses.length;

    // Identificamos cuáles gastos fijos tienen al menos un pago registrado este mes
    final paidIds = transactions.map((t) => t.relatedExpense.value?.id).whereType<int>().toSet();
    final paid = fixedExpenses.where((e) => paidIds.contains(e.id)).length;

    yield (paid: paid, total: total);
  }
});

// Balance de Ahorro Actual (Ingresos Ejecutados - Gastos Ejecutados)
final currentSavingsProvider = Provider<AsyncValue<double>>((ref) {
  final incomeAsync = ref.watch(incomeExecutedTotalProvider);
  final expenseAsync = ref.watch(executedTotalProvider); // Provider traído de expenses_screen.dart

  if (incomeAsync.isLoading || expenseAsync.isLoading) return const AsyncValue.loading();
  
  final income = incomeAsync.value ?? 0.0;
  final expense = expenseAsync.value ?? 0.0;
  
  return AsyncValue.data(income - expense);
});

// Fecha seleccionada para la planificación (Por defecto: Fecha actual)
final planningDateProvider = StateProvider<DateTime>((ref) {
  return ref.watch(nowProvider);
});

// Transacciones Reales del Mes (Para cálculo de flujo de caja en planificación)
final monthRealTransactionsProvider = StreamProvider<List<FinancialTransaction>>((ref) async* {
  final expenseDao = ref.watch(expenseDaoProvider);
  // Usamos la fecha de planificación seleccionada en lugar de 'now'
  final planningDate = ref.watch(planningDateProvider);
  final range = getCycleDateRange(planningDate, Frequency.monthly);
  
  // MODIFICADO: Ahora traemos TODAS las transacciones (Ingresos y Gastos) para calcular bien el flujo
  final isar = await expenseDao.isarService.db;
  yield* isar.financialTransactions.filter().dateBetween(range.start, range.end).watch(fireImmediately: true);
});

// --- PROVIDERS PARA PLANIFICACIÓN ---

// 1. Configuración de la Tabla (Columnas basadas en el Ingreso Principal)
final planningConfigProvider = FutureProvider<({int columns, List<double> columnIncomes, Frequency freq})>((ref) async {
  final isar = await ref.watch(isarServiceProvider).db;
  final incomes = await isar.recurringMovements.where().findAll();
  
  if (incomes.isEmpty) return (columns: 1, columnIncomes: [0.0], freq: Frequency.monthly);

  // Buscamos el ingreso que más dinero aporta al mes
  RecurringMovement? dominant;
  double maxMonthly = -1;

  for (var inc in incomes) {
    final total = (inc.paymentAmounts ?? []).fold(0.0, (s, e) => s + e);
    if (total > maxMonthly) {
      maxMonthly = total;
      dominant = inc;
    }
  }

  if (dominant == null) return (columns: 1, columnIncomes: [0.0], freq: Frequency.monthly);

  final freq = dominant.frequency;
  final amounts = dominant.paymentAmounts ?? [];
  int columns = 1;
  List<double> columnIncomes = [];
  
  // Definimos columnas y distribuimos los montos exactos
  switch (freq) {
    case Frequency.weekly:
      columns = 4; // Asumimos mes estándar de 4 semanas para visualización
      // Si hay montos definidos, los usamos, si no, promediamos o repetimos
      if (amounts.isNotEmpty) {
        columnIncomes = List.generate(4, (i) => i < amounts.length ? amounts[i] : amounts.last);
      } else {
        columnIncomes = List.filled(4, 0.0);
      }
      break;
    case Frequency.biweekly:
      columns = 2; // 2 Quincenas
      if (amounts.length >= 2) {
        // Lógica de Flujo de Caja:
        // El pago de fin de mes (index 1 usually) cubre el principio del siguiente (1-15).
        // El pago de quincena (index 0 usually) cubre el final del mes (16-30).
        // Asumimos que amounts viene ordenado [15, 30]. Invertimos para asignar a columnas [Col1(1-15), Col2(16-30)].
        columnIncomes = [amounts[1], amounts[0]];
      } else if (amounts.isNotEmpty) {
        columnIncomes = [amounts[0], amounts[0]];
      } else {
        columnIncomes = [0.0, 0.0];
      }
      break;
    default:
      columns = 1; // Mensual u otros
      columnIncomes = [maxMonthly];
  }

  return (columns: columns, columnIncomes: columnIncomes, freq: freq);
});

// 2. Controlador de Posiciones con Persistencia (Archivo JSON Local)
class PlanningPositionsController extends StateNotifier<Map<String, int?>> {
  PlanningPositionsController() : super({}) {
    _load();
  }

  static const _fileName = 'planning_layout.json';

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<void> _load() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final Map<String, dynamic> decoded = jsonDecode(jsonString);
        // Convertimos dynamic a int?
        final Map<String, int?> loaded = decoded.map((key, value) => MapEntry(key, value as int?));
        state = loaded;
      }
    } catch (e) {
      debugPrint("Error cargando planificación: $e");
    }
  }

  Future<void> _save() async {
    try {
      final file = await _getFile();
      // Filtramos los nulos para guardar solo lo asignado
      final toSave = Map<String, int>.fromEntries(
        state.entries.where((e) => e.value != null).map((e) => MapEntry(e.key, e.value!))
      );
      await file.writeAsString(jsonEncode(toSave));
    } catch (e) {
      debugPrint("Error guardando planificación: $e");
    }
  }

  void updatePosition(String id, int? column) {
    // Creamos un nuevo mapa para asegurar inmutabilidad
    final newState = Map<String, int?>.from(state);
    if (column == null) {
      newState.remove(id); // Si es null (pool), lo quitamos del mapa guardado
    } else {
      newState[id] = column;
    }
    state = newState;
    _save();
  }
}

final planningPositionsProvider = StateNotifierProvider<PlanningPositionsController, Map<String, int?>>((ref) {
  return PlanningPositionsController();
});

// 3. Provider auxiliar para obtener todos los gastos fijos (reutiliza el DAO)
final allFixedExpensesProvider = StreamProvider<List<Expense>>((ref) {
  return ref.watch(expenseDaoProvider).watchFixedExpenses();
});

// 4. Provider para obtener las DEUDAS del mes actual
final planningDebtsProvider = StreamProvider<List<Debt>>((ref) async* {
  final isar = await ref.watch(isarServiceProvider).db;
  // Traemos TODAS las deudas para poder calcular cuotas pasadas (pagadas) y futuras.
  // Filtraremos en memoria cuáles pertenecen a este mes.
  yield* isar.debts.where().watch(fireImmediately: true);
});

// --- PROVIDERS PARA EL NUEVO RESUMEN (FILTRADO) ---

enum SummaryFilter { currentPeriod, nextPeriod, currentMonth, nextMonth }

final summaryFilterProvider = StateProvider<SummaryFilter>((ref) => SummaryFilter.currentPeriod);

final homeSummaryDataProvider = FutureProvider<({double income, double expenses, double debts, double available})>((ref) async {
  final filter = ref.watch(summaryFilterProvider);
  final config = await ref.watch(planningConfigProvider.future);
  final expenses = await ref.watch(allFixedExpensesProvider.future);
  final allDebts = await ref.watch(planningDebtsProvider.future);
  final positions = ref.watch(planningPositionsProvider);
  final now = ref.watch(nowProvider);
  final debtDao = ref.watch(debtDaoProvider);

  // 1. Determinar índices de columnas (Periodos)
  int currentColumnIndex = 0;
  if (config.columns == 2) {
    currentColumnIndex = now.day <= 15 ? 0 : 1;
  } else if (config.columns == 4) {
    currentColumnIndex = ((now.day - 1) / 7).floor().clamp(0, 3);
  }

  // 2. Configurar el filtro
  int? targetColumn;
  bool isNextMonth = false;
  bool isFullMonth = false;

  switch (filter) {
    case SummaryFilter.currentPeriod:
      targetColumn = currentColumnIndex;
      break;
    case SummaryFilter.nextPeriod:
      targetColumn = currentColumnIndex + 1;
      if (targetColumn >= config.columns) {
        // Si se pasa de columnas, es el primer periodo del próximo mes
        targetColumn = 0;
        isNextMonth = true;
      }
      break;
    case SummaryFilter.currentMonth:
      isFullMonth = true;
      break;
    case SummaryFilter.nextMonth:
      isNextMonth = true;
      isFullMonth = true;
      break;
  }

  // 3. Calcular Ingresos
  double income = 0.0;
  if (isFullMonth) {
    // Suma de todos los ingresos del mes (usamos la config de columnas como base)
    income = config.columnIncomes.fold(0.0, (sum, val) => sum + val);
  } else {
    // Ingreso de la columna específica
    income = (targetColumn != null && targetColumn < config.columnIncomes.length) 
        ? config.columnIncomes[targetColumn] 
        : 0.0;
  }

  // 4. Calcular Gastos (Fijos y Deudas)
  double totalExpenses = 0.0;
  double totalDebts = 0.0;
  
  // Helper para saber si una columna cuenta para el filtro actual
  bool isColumnIncluded(int? colIndex) {
    if (isFullMonth) return true; // En vista mensual sumamos todo (o todo lo asignado)
    return colIndex == targetColumn;
  }

  // A. GASTOS FIJOS
  // Si es vista de MES COMPLETO, sumamos el total proyectado de todos los gastos activos.
  if (isFullMonth) {
    totalExpenses = expenses.fold(0.0, (sum, e) => sum + e.amount);
  } else {
    // Si es vista de PERIODO (Pago Actual/Siguiente), usamos la PLANIFICACIÓN (Posiciones)
    // 1. Agrupamos gastos por categoría para replicar la lógica de bloques
    final Map<int, ({double amount, Frequency freq})> categoryData = {};
    for (var e in expenses) {
       final cat = e.category.value;
       if (cat == null) continue;
       final current = categoryData[cat.id] ?? (amount: 0.0, freq: e.frequency);
       categoryData[cat.id] = (amount: current.amount + e.amount, freq: current.freq);
    }

    // 2. Iteramos los bloques teóricos y sumamos solo si están asignados a la columna target
    categoryData.forEach((catId, data) {
        int blocksCount = 1;
        if (data.freq == Frequency.weekly) blocksCount = 4;
        if (data.freq == Frequency.biweekly) blocksCount = 2;

        for (int i = 0; i < blocksCount; i++) {
            final blockId = "cat_${catId}_$i";
            // Verificamos si el usuario asignó este bloque a la columna que estamos viendo
            if (positions[blockId] == targetColumn) {
                totalExpenses += data.amount;
            }
        }
    });
  }

  // B. DEUDAS
  // Definimos el mes de referencia para generar los bloques de deuda
  DateTime generationDate = isNextMonth ? DateTime(now.year, now.month + 1, 1) : now;
  DateTime startOfMonth = DateTime(generationDate.year, generationDate.month, 1);
  DateTime endOfMonth = DateTime(generationDate.year, generationDate.month + 1, 0, 23, 59, 59);

  for (var debt in allDebts) {
    DateTime? date = debt.nextPaymentDate;
    if (date != null) {
       // Avanzamos la fecha hasta llegar al mes de generación si es necesario
       if (date.isBefore(startOfMonth)) {
          while(date!.isBefore(startOfMonth)) {
             date = debtDao.calculateNextPaymentDate(date, debt.frequency, debt.customDays);
          }
       }
       
       // Iteramos todas las cuotas dentro del mes
       while (date!.isBefore(endOfMonth) || date.isAtSameMomentAs(endOfMonth)) {
         if (isFullMonth) {
           // Si es mes completo, sumamos todo
           totalDebts += debt.installmentAmount;
         } else {
           // Si es periodo, verificamos si el bloque de deuda está asignado a la columna target
           final blockId = "debt_${debt.id}_${date.day}";
           // Nota: Si el usuario no ha movido la deuda, positions[blockId] es null.
           // Asumimos que para el resumen de "Pago Actual" solo cuenta lo explícitamente asignado o forzado.
           if (positions[blockId] == targetColumn) {
              totalDebts += debt.installmentAmount;
           }
         }
         date = debtDao.calculateNextPaymentDate(date, debt.frequency, debt.customDays);
       }
    }
  }

  return (
    income: income,
    expenses: totalExpenses,
    debts: totalDebts,
    available: (income - totalExpenses - totalDebts).clamp(0.0, double.infinity)
  );
});

// --- PANTALLA PRINCIPAL ---

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        // Quitamos el título y reducimos la altura para ganar espacio
        toolbarHeight: 0, 
        backgroundColor: colors.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          indicatorColor: colors.primary,
          labelColor: colors.primary,
          unselectedLabelColor: colors.outline,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: "Resumen", icon: Icon(Icons.dashboard_outlined)),
            Tab(text: "Planificación", icon: Icon(Icons.calendar_month_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _SummaryTab(),
          _PlanningTab(),
        ],
      ),
    );
  }
}

// --- PESTAÑA DE RESUMEN ---

class _SummaryTab extends ConsumerWidget {
  const _SummaryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observamos el filtro para cambiar la Key del gráfico y forzar su animación de entrada
    final filter = ref.watch(summaryFilterProvider);
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        children: [
          const Gap(10),
          const _SummaryFilterSelector(),
          const Gap(20),
          _HomeChartSection(key: ValueKey(filter)),
          const Gap(30),
          const _HomeInfoCards(),
        ],
      ),
    );
  }
}

class _SummaryFilterSelector extends ConsumerWidget {
  const _SummaryFilterSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(summaryFilterProvider);
    final colors = Theme.of(context).colorScheme;

    Widget buildOption(String label, SummaryFilter value) {
      final isSelected = selected == value;
      return GestureDetector(
        onTap: () => ref.read(summaryFilterProvider.notifier).state = value,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? colors.primary : colors.outlineVariant.withAlpha(100),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          buildOption("Pago Actual", SummaryFilter.currentPeriod),
          const Gap(8),
          buildOption("Siguiente Pago", SummaryFilter.nextPeriod),
          const Gap(8),
          buildOption("Mes", SummaryFilter.currentMonth),
          const Gap(8),
          buildOption("Próximo Mes", SummaryFilter.nextMonth),
        ],
      ),
    );
  }
}

// --- PESTAÑA DE PLANIFICACIÓN ---

class _PlanningTab extends ConsumerWidget {
  const _PlanningTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final configAsync = ref.watch(planningConfigProvider);
    final expensesAsync = ref.watch(allFixedExpensesProvider);
    final debtsAsync = ref.watch(planningDebtsProvider);
    final positions = ref.watch(planningPositionsProvider);
    final realTransactionsAsync = ref.watch(monthRealTransactionsProvider);

    if (configAsync.isLoading || expensesAsync.isLoading || debtsAsync.isLoading || realTransactionsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final config = configAsync.value ?? (columns: 1, columnIncomes: [0.0], freq: Frequency.monthly);
    final expenses = expensesAsync.value ?? [];
    final debts = debtsAsync.value ?? [];
    final realTransactions = realTransactionsAsync.value ?? [];
    
    // Fecha base para la planificación
    final planningDate = ref.watch(planningDateProvider);

    // 1. Agrupamos gastos por Categoría y calculamos contadores (Pagados vs Total)
    final Map<int, ({String name, int icon, int color, double amount, Frequency frequency, int totalCount, int paidCount})> groupedExpenses = {};

    // Identificamos qué gastos (IDs) ya tienen pago este mes
    final paidExpenseIds = realTransactions
        .where((t) => t.relatedExpense.value != null)
        .map((t) => t.relatedExpense.value!.id)
        .toSet();

    for (var e in expenses) {
      final cat = e.category.value;
      if (cat == null) continue;
      
      final isPaid = paidExpenseIds.contains(e.id);

      final current = groupedExpenses[cat.id] ?? (
        name: cat.name, 
        icon: cat.iconCode, 
        color: cat.colorValue, 
        amount: 0.0, 
        frequency: e.frequency,
        totalCount: 0,
        paidCount: 0
      );

      groupedExpenses[cat.id] = (
        name: current.name,
        icon: current.icon,
        color: current.color,
        amount: current.amount + e.amount,
        frequency: current.frequency,
        totalCount: current.totalCount + 1,
        paidCount: current.paidCount + (isPaid ? 1 : 0)
      );
    }

    // 2. Generamos los bloques visuales
    // Estructura extendida para soportar bloqueo y estado
    final List<({String id, String name, int icon, int color, double amount, String? subtitle, bool isLocked, int? paidCount, int? totalCount})> blocks = [];
    
    groupedExpenses.forEach((catId, data) {
      int blocksCount = 1;
      if (data.frequency == Frequency.weekly) blocksCount = 4;
      if (data.frequency == Frequency.biweekly) blocksCount = 2;
      
      for (int i = 0; i < blocksCount; i++) {
        blocks.add((
          id: "cat_${catId}_$i", 
          name: data.name,
          icon: data.icon,
          color: data.color,
          amount: data.amount,
          subtitle: null,
          isLocked: false, // Por defecto desbloqueado
          paidCount: data.paidCount,
          totalCount: data.totalCount,
        ));
      }
    });

    // 3. Agregamos las DEUDAS como bloques
    // LÓGICA MEJORADA: Generar un bloque por CADA cuota dentro del mes actual
    final startOfMonth = DateTime(planningDate.year, planningDate.month, 1);
    final endOfMonth = DateTime(planningDate.year, planningDate.month + 1, 0, 23, 59, 59);
    final debtDao = ref.watch(debtDaoProvider); // Necesitamos el DAO para calcular fechas

    for (var debt in debts) {
      // Usamos la fecha de próximo pago como ancla.
      DateTime? anchorDate = debt.nextPaymentDate;
      
      // 1. Generamos bloques futuros desde anchorDate
      if (anchorDate != null) {
        DateTime date = anchorDate;
        while (date.isBefore(endOfMonth) || date.isAtSameMomentAs(endOfMonth)) {
          // ID estable basado en el día: debt_ID_DIA
          // Solo agregamos si cae dentro del mes seleccionado (para evitar duplicados de meses anteriores si el loop empieza antes)
          if (date.isAfter(startOfMonth.subtract(const Duration(seconds: 1)))) {
            final blockId = "debt_${debt.id}_${date.day}";
            
            blocks.add((
              id: blockId,
              name: debt.title,
              icon: FontAwesomeIcons.fileInvoiceDollar.codePoint,
              color: const Color(0xFFE17055).value, // Terracota para Deudas
              amount: debt.installmentAmount,
              subtitle: "Vence: ${DateFormat('d MMM', 'es').format(date)}",
              isLocked: false,
              paidCount: null,
              totalCount: null,
            ));
          }
          date = debtDao.calculateNextPaymentDate(date, debt.frequency, debt.customDays);
        }
      }
    }

    // 4. LÓGICA DE BLOQUEO Y MOVIMIENTO AUTOMÁTICO (REAL WORLD OVERRIDE)
    // Iteramos las transacciones reales para "forzar" la posición de los bloques y bloquearlos.
    
    // Mapa temporal para saber qué posiciones forzar visualmente
    final Map<String, int> forcedPositions = {};
    // Conjunto de IDs bloqueados
    final Set<String> lockedIds = {};

    // Helper para calcular columna basada en fecha
    int getColumnForDate(DateTime date) {
      if (config.columns == 2) {
        return date.day <= 15 ? 0 : 1;
      } else if (config.columns == 4) {
        // Aprox semanal
        int week = ((date.day - 1) / 7).floor();
        if (week > 3) week = 3;
        return week;
      }
      return 0; // Mensual
    }

    for (var tx in realTransactions) {
      // CASO DEUDA PAGADA
      if (tx.relatedDebt.value != null) {
        final debt = tx.relatedDebt.value!;
        final colIndex = getColumnForDate(tx.date);
        final debtPrefix = "debt_${debt.id}_";
        
        // ✅ LÓGICA INTELIGENTE:
        // 1. Buscamos si existe un bloque exacto para ese día (pago puntual).
        int existingIndex = blocks.indexWhere((b) => b.id == "debt_${debt.id}_${tx.date.day}");
        
        // 2. Si no, buscamos CUALQUIER bloque de esta deuda que no esté bloqueado todavía.
        // Esto evita duplicados: si pagaste el 14 lo del 15, tomamos el bloque del 15 y lo actualizamos.
        if (existingIndex == -1) {
          existingIndex = blocks.indexWhere((b) => b.id.startsWith(debtPrefix) && !b.isLocked);
        }
        
        if (existingIndex != -1) {
          // Si existe, lo actualizamos
          blocks[existingIndex] = (
            id: blocks[existingIndex].id,
            name: blocks[existingIndex].name,
            icon: blocks[existingIndex].icon,
            color: blocks[existingIndex].color,
            amount: blocks[existingIndex].amount,
            subtitle: "Pagado el ${tx.date.day}",
            isLocked: true, // BLOQUEADO
            paidCount: null,
            totalCount: null,
          );
        } else {
          // Si no existe (porque era una cuota pasada que ya no sale en pendientes), lo creamos
          final blockId = "debt_${debt.id}_${tx.date.day}";
          blocks.add((
            id: blockId,
            name: debt.title,
            icon: FontAwesomeIcons.fileInvoiceDollar.codePoint,
            color: const Color(0xFFE17055).value, // Terracota
            amount: tx.amount, // Usamos el monto real pagado
            subtitle: "Pagado el ${tx.date.day}",
            isLocked: true, // BLOQUEADO
            paidCount: null,
            totalCount: null,
          ));
          forcedPositions[blockId] = colIndex;
          lockedIds.add(blockId);
        }
        
        if (existingIndex != -1) {
           forcedPositions[blocks[existingIndex].id] = colIndex;
           lockedIds.add(blocks[existingIndex].id);
        }
      }
      
      // CASO CATEGORÍA PAGADA
      // Si hay un pago de categoría, buscamos un bloque disponible de esa categoría y lo movemos/bloqueamos.
      else if (tx.isRecurring && tx.relatedExpense.value != null) {
        final cat = tx.relatedExpense.value!.category.value;
        if (cat != null) {
          final colIndex = getColumnForDate(tx.date);
          final catPrefix = "cat_${cat.id}_";
          
          // Buscamos el primer bloque de esta categoría que NO esté ya bloqueado
          // Esto distribuye los pagos entre los bloques disponibles (ej: 4 semanas)
          final blockIndex = blocks.indexWhere((b) => b.id.startsWith(catPrefix) && !lockedIds.contains(b.id));
          
          if (blockIndex != -1) {
            final block = blocks[blockIndex];
            // Lo marcamos como bloqueado
            blocks[blockIndex] = (
              id: block.id,
              name: block.name,
              icon: block.icon,
              color: block.color,
              amount: block.amount,
              subtitle: "Pago realizado",
              isLocked: true,
              paidCount: block.paidCount,
              totalCount: block.totalCount,
            );
            
            forcedPositions[block.id] = colIndex;
            lockedIds.add(block.id);
          }
        }
      }
    }

    // Separamos bloques asignados de los no asignados (Pool)
    // Un bloque está en el pool si: NO tiene posición guardada Y NO tiene posición forzada.
    final unassignedBlocks = blocks.where((b) {
      if (forcedPositions.containsKey(b.id)) return false; // Si está forzado, no está en pool
      return positions[b.id] == null;
    }).toList();

    return Column(
      children: [
        // Selector de Mes para Planificación
        const _PlanningDateSelector(),
        const Gap(10),
        // --- ÁREA DE COLUMNAS (TABLA) ---
        Expanded(
          child: DragTarget<String>(
            // Permitir soltar de vuelta al área general (opcional, aquí lo manejamos si se suelta fuera de columnas podría volver al pool si quisiéramos)
            builder: (context, _, __) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(config.columns, (colIndex) {
                  // Filtramos los bloques que están en esta columna
                  final columnBlocks = blocks.where((b) {
                    // Prioridad: Posición Forzada (Pago Real) > Posición Guardada
                    if (forcedPositions.containsKey(b.id)) {
                      return forcedPositions[b.id] == colIndex;
                    }
                    return positions[b.id] == colIndex;
                  }).toList();

                  // Obtenemos el ingreso específico de esta columna
                  final colIncome = config.columnIncomes.length > colIndex ? config.columnIncomes[colIndex] : 0.0;
                  
                  // Calculamos totales
                  final totalExpenses = columnBlocks.fold(0.0, (sum, b) => sum + b.amount);
                  final remaining = colIncome - totalExpenses;

                  return Expanded(
                    child: _PlanningColumn(
                      index: colIndex,
                      planningDate: planningDate, // Pasamos la fecha seleccionada
                      totalColumns: config.columns,
                      income: colIncome,
                      totalExpenses: totalExpenses,
                      remaining: remaining,
                      blocks: columnBlocks,
                      allRealTransactions: realTransactions, // Pasamos las transacciones reales
                      onDrop: (blockId) {
                        // Actualizamos el estado local: Asignar a columna
                        ref.read(planningPositionsProvider.notifier).updatePosition(blockId, colIndex);
                      },
                    ),
                  );
                }),
              );
            },
          ),
        ),

        // --- ÁREA DE POOL (GASTOS POR ASIGNAR) ---
        // Movido abajo y con más altura para evitar overflow
        DragTarget<String>(
          onWillAcceptWithDetails: (_) => true,
          onAcceptWithDetails: (details) {
            // Al soltar aquí, devolvemos el gasto al pool (posición null)
            ref.read(planningPositionsProvider.notifier).updatePosition(details.data, null);
          },
          builder: (context, candidateData, rejectedData) {
            final isHovered = candidateData.isNotEmpty;
            return Container(
              height: 180, 
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isHovered ? colors.primaryContainer.withAlpha(50) : colors.surfaceContainerHighest.withAlpha(100),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isHovered ? colors.primary : colors.outlineVariant.withAlpha(100)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Gastos por Asignar (${unassignedBlocks.length})",
                    style: TextStyle(fontSize: 12, color: colors.outline, fontWeight: FontWeight.bold),
                  ),
                  const Gap(8),
                  Expanded(
                    child: unassignedBlocks.isEmpty 
                    ? Center(child: Text("¡Todo planificado!", style: TextStyle(fontSize: 12, color: colors.primary)))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Wrap(
                          direction: Axis.vertical,
                          spacing: 8,
                          runSpacing: 8,
                          children: unassignedBlocks.map((b) {
                            return Draggable<String>(
                              data: b.id,
                              // Si está bloqueado, deshabilitamos el arrastre (maxSimultaneousDrags: 0)
                              maxSimultaneousDrags: b.isLocked ? 0 : 1,
                              feedback: Material(
                                color: Colors.transparent,
                                child: Opacity(opacity: 0.9, child: _ExpenseBlock(id: b.id, name: b.name, icon: b.icon, color: b.color, amount: b.amount, subtitle: b.subtitle, isLocked: b.isLocked, paidCount: b.paidCount, totalCount: b.totalCount, isCompact: true)),
                              ),
                              childWhenDragging: Opacity(opacity: 0.3, child: _ExpenseBlock(id: b.id, name: b.name, icon: b.icon, color: b.color, amount: b.amount, subtitle: b.subtitle, isLocked: b.isLocked, paidCount: b.paidCount, totalCount: b.totalCount, isCompact: true)),
                              child: _ExpenseBlock(id: b.id, name: b.name, icon: b.icon, color: b.color, amount: b.amount, subtitle: b.subtitle, isLocked: b.isLocked, paidCount: b.paidCount, totalCount: b.totalCount, isCompact: true),
                            );
                          }).toList(),
                        ),
                      ),
                  ),
                ],
              ),
            );
          }
        ),
      ],
    );
  }
}

class _PlanningColumn extends StatelessWidget {
  final int index;
  final DateTime planningDate;
  final int totalColumns;
  final double income;
  final double totalExpenses;
  final double remaining;
  final List<dynamic> blocks; // Lista de bloques en esta columna
  final List<FinancialTransaction> allRealTransactions; // Todas las transacciones del mes
  final Function(String) onDrop;

  const _PlanningColumn({
    required this.index,
    required this.planningDate,
    required this.totalColumns,
    required this.income,
    required this.totalExpenses,
    required this.remaining,
    required this.blocks,
    required this.allRealTransactions,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Usamos la fecha de planificación para los cálculos
    final baseDate = planningDate;

    // Título y Fechas Dinámicas
    String title = "";
    String dateRange = "";
    DateTime colStart;
    DateTime colEnd;

    if (totalColumns == 2) {
      // Lógica Quincenal
      if (index == 0) {
        title = "Pago Fin de Mes";
        dateRange = "Cubre: 1 - 15 ${DateFormat('MMM', 'es').format(baseDate)}";
        colStart = DateTime(baseDate.year, baseDate.month, 1);
        colEnd = DateTime(baseDate.year, baseDate.month, 15, 23, 59, 59);
      } else {
        title = "Pago Quincena";
        dateRange = "Cubre: 16 - ${DateTime(baseDate.year, baseDate.month + 1, 0).day} ${DateFormat('MMM', 'es').format(baseDate)}";
        colStart = DateTime(baseDate.year, baseDate.month, 16);
        colEnd = DateTime(baseDate.year, baseDate.month + 1, 0, 23, 59, 59);
      }
    } else if (totalColumns == 4) {
      title = "Semana ${index + 1}";
      dateRange = ""; // Simplificado para semanal
      // Cálculo aproximado de semanas
      colStart = DateTime(baseDate.year, baseDate.month, 1).add(Duration(days: index * 7));
      colEnd = colStart.add(const Duration(days: 6, hours: 23, minutes: 59));
    } else {
      title = "Mes Completo";
      dateRange = DateFormat('MMMM', 'es').format(baseDate);
      colStart = DateTime(baseDate.year, baseDate.month, 1);
      colEnd = DateTime(baseDate.year, baseDate.month + 1, 0, 23, 59, 59);
    }

    // --- CÁLCULO DEL DISPONIBLE REAL (JACKPOT) ---
    
    // 1. Filtramos transacciones reales que ocurrieron en el rango de esta columna
    final colTransactions = allRealTransactions.where((t) => 
      t.date.isAfter(colStart.subtract(const Duration(seconds: 1))) && 
      t.date.isBefore(colEnd.add(const Duration(seconds: 1)))
    ).toList();

    // 2. Sumamos todo lo gastado realmente en este periodo (Solo Gastos)
    final realTotalSpent = colTransactions
        .where((t) => t.type == TransactionType.expense || t.type == TransactionType.saving) // Incluimos Ahorros
        .fold(0.0, (sum, t) => sum + t.amount);

    // 2.1 Sumamos los INGRESOS EXTRAS reales en este periodo (Corrección solicitada)
    // Ingresos que NO son recurrentes (porque los recurrentes ya están en 'income')
    final realExtraIncome = colTransactions
        .where((t) => t.type == TransactionType.income && !t.isRecurring)
        .fold(0.0, (sum, t) => sum + t.amount);

    // 3. Calculamos cuánto de lo "Planificado" ya se pagó para no restarlo dos veces.
    //    (Si planifiqué 50 y pagué 45, resto 45 real y 5 remanente planificado = 50 total).
    //    (Si planifiqué 50 y pagué 50, resto 50 real y 0 remanente).
    
    double matchedProjectedAmount = 0.0;

    // Mapa temporal para controlar qué bloques fijos ya se "cubrieron" con transacciones
    // Clave: CategoryID (porque los bloques fijos son por categoría)
    // Valor: Monto acumulado de bloques en esta columna
    final Map<int, double> categoryBlockPool = {};
    // Mapa para controlar bloques de deuda
    // Clave: DebtID
    // Valor: Monto acumulado de bloques de esa deuda en esta columna
    final Map<int, double> debtBlockPool = {};

    for (var b in blocks) {
      // Solo nos interesan los bloques de gastos fijos (cat_...) para el matching
      if (b.id.toString().startsWith("cat_")) {
        final parts = b.id.toString().split('_');
        if (parts.length >= 2) {
          final catId = int.tryParse(parts[1]) ?? -1;
          categoryBlockPool[catId] = (categoryBlockPool[catId] ?? 0.0) + b.amount;
        }
      }
      // También nos interesan los bloques de deuda (debt_...)
      if (b.id.toString().startsWith("debt_")) {
        final parts = b.id.toString().split('_');
        if (parts.length >= 2) {
          final debtId = int.tryParse(parts[1]) ?? -1;
          debtBlockPool[debtId] = (debtBlockPool[debtId] ?? 0.0) + b.amount;
        }
      }
    }

    for (var tx in colTransactions) {
      // CASO DEUDA: Si es un pago de deuda
      if (tx.relatedDebt.value != null) {
        final debtId = tx.relatedDebt.value!.id;
        // Verificamos si había un bloque planificado para esta deuda en esta columna
        if (debtBlockPool.containsKey(debtId)) {
          // Si existe, significa que estaba planificado.
          // Sumamos al 'matched' para anular la doble resta.
          // (Se resta en 'realTotalSpent' y se resta en 'totalExpenses', así que sumamos aquí para compensar).
          double planned = debtBlockPool[debtId] ?? 0.0;
          double match = tx.amount;
          // No podemos matchear más de lo planificado
          if (match > planned) match = planned;
          
          matchedProjectedAmount += match;
          
          // Reducimos el pool disponible de esa deuda
          debtBlockPool[debtId] = planned - match;
        }
      }
      // CASO GASTO FIJO: Si es un gasto fijo (recurrente) y no es deuda
      else if (tx.isRecurring) {
        // Intentamos encontrar un bloque de categoría que coincida
        // Nota: FinancialTransaction no guarda catId directo fácilmente accesible sin cargar, 
        // pero relatedExpense -> category -> id sí. Asumimos que la lógica de negocio mantiene consistencia.
        // Para simplificar y ser robustos, usamos el matching visual si es posible, o asumimos que
        // si hay un gasto recurrente real, "consume" presupuesto planificado.
        
        // Estrategia Simplificada Robusta:
        // Si hay una transacción recurrente real, asumimos que cubre parte del planificado.
        // Sumamos su monto "teórico" (el del bloque) a matchedProjectedAmount.
        // Como no tenemos el monto teórico a mano en la tx, usamos el monto real como proxy 
        // O mejor: Si el bloque existe, lo descontamos.
        
        // Vamos a iterar sobre el pool. Si encontramos un bloque de la misma categoría (por nombre o icono), lo "consumimos".
        // FinancialTransaction tiene categoryName e iconCode.
        
        // MEJORA: Usamos el monto de la transacción como "monto planificado cubierto" 
        // hasta el tope del bloque disponible. Esto maneja el caso "ahorré dinero".
        // Si planifiqué 50 y gasté 45 -> Real 45. Matched 45. 
        // Formula: Income - Real(45) - (Planned(50) - Matched(45)) = Income - 50. Correcto.
        // Si planifiqué 50 y gasté 55 -> Real 55. Matched 50 (tope).
        // Formula: Income - 55 - (50 - 50) = Income - 55. Correcto.
        
        // Para implementar esto sin ID exacto, asumiremos que los gastos recurrentes
        // siempre "intentan" cubrir bloques planificados en la columna.
        matchedProjectedAmount += tx.amount; 
      }
    }
    
    // Ajuste final: Matched no puede superar lo planificado total (para no sumar dinero mágicamente)
    if (matchedProjectedAmount > totalExpenses) {
      matchedProjectedAmount = totalExpenses;
    }

    // FÓRMULA MAESTRA:
    // Disponible = (IngresoColumna + ExtraIncome) - GastosReales - (Planificado - LoQueYaSePagoDeLoPlanificado)
    // (Planificado - LoQueYaSePago) = "Planificado Pendiente"
    final realRemaining = (income + realExtraIncome) - realTotalSpent - (totalExpenses - matchedProjectedAmount);

    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: isHovered ? colors.primaryContainer.withAlpha(50) : colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered ? colors.primary : colors.outlineVariant.withAlpha(80), 
              width: 1
            ),
            boxShadow: [
              if (!isHovered) BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2))
            ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Ocupar todo el ancho
            children: [
              // Header de la Columna
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: colors.onSurface, fontSize: 14)),
                    Text(dateRange, style: TextStyle(fontSize: 10, color: colors.outline)),
                    const Gap(8),
                    // Animación Jackpot del monto restante
                    _JackpotNumber(
                      value: realRemaining, // Usamos el cálculo real
                      color: realRemaining >= 0 ? const Color(0xFF1DD1A1) : const Color(0xFFFF6B6B),
                    ),
                  ],
                ),
              ),
              // Lista de Bloques
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: blocks.length,
                  separatorBuilder: (_, __) => const Gap(8),
                  itemBuilder: (context, i) {
                    final block = blocks[i];
                    return _ExpenseBlock(
                      id: block.id, 
                      name: block.name,
                      icon: block.icon,
                      color: block.color,
                      amount: block.amount,
                      subtitle: block.subtitle,
                      isLocked: block.isLocked,
                      paidCount: block.paidCount,
                      totalCount: block.totalCount,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExpenseBlock extends StatelessWidget {
  final String id;
  final String name;
  final int icon;
  final int color;
  final double amount;
  final String? subtitle;
  final bool isLocked;
  final int? paidCount;
  final int? totalCount;
  final bool isCompact;

  const _ExpenseBlock({
    required this.id, 
    required this.name,
    required this.icon,
    required this.color,
    required this.amount,
    this.subtitle,
    this.isLocked = false,
    this.paidCount,
    this.totalCount,
    this.isCompact = false
  });

  @override
  Widget build(BuildContext context) {
    final blockColor = Color(color);
    // Usamos el mapper para obtener el icono correcto (FontAwesome/Material)
    final blockIcon = getIconFromCode(icon);
    
    // Indicador de Pagos (ej: 2/5)
    final bool showCounter = totalCount != null && totalCount! > 0;
    final bool allPaid = showCounter && paidCount == totalCount;

    // Diseño del bloque renovado (Más espacioso y limpio)
    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: blockColor,
        borderRadius: BorderRadius.circular(16),
        border: allPaid ? Border.all(color: Colors.greenAccent, width: 2) : null, // Borde verde si todo pagado
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: blockColor.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                // Icono original siempre
                child: Icon(blockIcon, color: Colors.white, size: 16),
              ),
              // Check verde a la derecha del icono si todo está pagado
              if (allPaid) ...[
                const Gap(4),
                const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
              ],
              const Gap(8),
              Expanded(
                child: Text(
                  name, 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const Gap(10),
          Text(
            NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 0).format(amount),
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          if (subtitle != null) ...[
            const Gap(4),
            Text(
              subtitle!,
              // ignore: deprecated_member_use
              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 10, fontStyle: FontStyle.italic),
            ),
          ],
          // Indicador de Pagos (2/5) y Candado (Encima del contador)
          if (!isCompact) ...[
             const Gap(4),
             Align(
               alignment: Alignment.centerRight,
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.end,
                 children: [
                   if (isLocked) ...[
                     const Icon(Icons.lock, color: Colors.white70, size: 12),
                     if (showCounter) const Gap(2),
                   ],
                   if (showCounter)
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                       decoration: BoxDecoration(
                         color: Colors.black26,
                         borderRadius: BorderRadius.circular(8)
                       ),
                       child: Text(
                         "$paidCount/$totalCount",
                         style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                       ),
                     ),
                 ],
               ),
             )
          ]
        ],
      ),
    );

    if (isCompact) {
      content = SizedBox(
        width: 130, // Un poco más ancho para que quepa mejor la info
        child: content,
      );
    }

    // Envolvemos en InkWell para detectar toques en bloques bloqueados
    return InkWell(
      onTap: isLocked ? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Este bloque está bloqueado porque el pago ya fue realizado ($subtitle)."),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          )
        );
      } : null,
      child: Draggable<String>(
        data: id,
        // Si está bloqueado, no permitimos arrastrar
        maxSimultaneousDrags: isLocked ? 0 : 1,
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: 110, // Ancho fijo para el feedback
            child: Opacity(opacity: 0.9, child: _ExpenseBlock(id: id, name: name, icon: icon, color: color, amount: amount, subtitle: subtitle, isLocked: isLocked, paidCount: paidCount, totalCount: totalCount, isCompact: false)),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: content),
        child: content,
      ),
    );
  }
}

// --- SELECTOR DE FECHA PARA PLANIFICACIÓN ---

class _PlanningDateSelector extends ConsumerWidget {
  const _PlanningDateSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(planningDateProvider);
    final now = ref.watch(nowProvider);
    
    bool isSameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;
    
    final isThisMonth = isSameMonth(selectedDate, now);
    final nextMonthDate = DateTime(now.year, now.month + 1, 1);
    final isNextMonth = isSameMonth(selectedDate, nextMonthDate);
    final isOther = !isThisMonth && !isNextMonth;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           _buildChip(context, ref, "Este Mes", isThisMonth, () => ref.read(planningDateProvider.notifier).state = now),
           const Gap(8),
           _buildChip(context, ref, "Próximo Mes", isNextMonth, () => ref.read(planningDateProvider.notifier).state = nextMonthDate),
           const Gap(8),
           _buildChip(context, ref, isOther ? DateFormat('MMMM y', 'es').format(selectedDate).toUpperCase() : "Otro Mes", isOther, () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: isOther ? selectedDate : nextMonthDate,
                firstDate: DateTime(now.year, now.month, 1),
                lastDate: DateTime(now.year + 5),
                locale: const Locale('es', 'ES'),
              );
              if (picked != null) {
                ref.read(planningDateProvider.notifier).state = picked;
              }
           }),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, WidgetRef ref, String label, bool isSelected, VoidCallback onTap) {
     final colors = Theme.of(context).colorScheme;
     return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? colors.primary : colors.outlineVariant.withAlpha(100)),
          ),
          child: Text(label, style: TextStyle(color: isSelected ? colors.onPrimary : colors.onSurfaceVariant, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
        ),
     );
  }
}

// --- WIDGET DE ANIMACIÓN JACKPOT ---

class _JackpotNumber extends StatelessWidget {
  final double value;
  final Color color;

  const _JackpotNumber({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 0);
    
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: value, end: value),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack, // Efecto de rebote al final
      builder: (context, val, child) {
        return Text(
          currency.format(val),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 26,
            letterSpacing: -1.0,
          ),
          textAlign: TextAlign.center,
        );
      },
    );
  }
}

// --- SECCIÓN DEL GRÁFICO (DONA) ---

class _HomeChartSection extends ConsumerStatefulWidget {
  const _HomeChartSection({super.key});

  @override
  ConsumerState<_HomeChartSection> createState() => _HomeChartSectionState();
}

class _HomeChartSectionState extends ConsumerState<_HomeChartSection> {
  bool _animate = false;

  @override
  void initState() {
    super.initState();
    // Retrasamos ligeramente la animación para que el gráfico arranque desde 0 y crezca
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _animate = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(homeSummaryDataProvider);

    return summaryAsync.when(
      loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox(height: 220, child: Center(child: Text("Error al cargar datos"))),
      data: (realData) {
        // Si estamos animando, usamos los datos reales. Si no, partimos de 0 para el efecto "grow".
        final data = _animate ? realData : (income: 0.0, expenses: 0.0, debts: 0.0, available: 0.0);
        final remaining = data.available;

        // Verificamos si los datos REALES están vacíos para mostrar el mensaje, no los datos de animación
        if (_animate && realData.income == 0 && realData.expenses == 0 && realData.debts == 0) {
       return SizedBox(
         height: 220, 
         child: Center(child: Text("Sin datos para proyectar", style: TextStyle(color: Theme.of(context).colorScheme.outline)))
       );
    }

    // Secciones del gráfico
    final sections = [
      // 1. Ingresos (Teal)
      if (data.income > 0)
        PieChartSectionData(
          value: data.income,
          color: const Color(0xFF1DD1A1), // Esmeralda (Ingreso Real)
          radius: 35, // Radio aumentado
          showTitle: false,
          // Efecto de luz/glow solicitado
          borderSide: BorderSide(color: const Color(0xFF1DD1A1).withAlpha(100), width: 6),
        ),
      // 2. Gastos (Naranja)
      if (data.expenses > 0)
        PieChartSectionData(
          value: data.expenses,
          color: const Color(0xFFFF6B6B), // Coral (Gastos)
          radius: 35,
          showTitle: false,
          borderSide: BorderSide(color: const Color(0xFFFF6B6B).withAlpha(100), width: 6),
        ),
      // 3. Deudas (Morado)
      if (data.debts > 0)
        PieChartSectionData(
          value: data.debts,
          color: const Color(0xFFE17055), // Terracota (Deudas)
          radius: 35,
          showTitle: false,
          borderSide: BorderSide(color: const Color(0xFFE17055).withAlpha(100), width: 6),
        ),
    ];

    final currencyFormat = NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 0);

    // Usamos TweenAnimationBuilder para animar el valor del texto central
    return SizedBox(
      height: 220, // Altura ajustada para subir el círculo
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: sections.isEmpty 
                ? [PieChartSectionData(value: 1, color: Colors.grey.shade200, radius: 25, showTitle: false)] 
                : sections,
              centerSpaceRadius: 75, // Radio interno más amplio estilo iOS/FinApp
              sectionsSpace: 4,
              startDegreeOffset: 270, // El gráfico empieza desde arriba (las 12 en punto)
            ),
            swapAnimationDuration: const Duration(milliseconds: 800),
            swapAnimationCurve: Curves.easeInOutCubic,
          ),
          // Texto central
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Disponible", style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 14)),
              const Gap(4),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: remaining),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutSine,
                builder: (context, value, child) {
                  return Text(
                    currencyFormat.format(value),
                    style: TextStyle(
                      fontSize: 32, 
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -1,
                    ),
                  );
                },
              ),
            ],
          )
        ],
      ),
    );
      },
    );
  }
}

// --- TARJETAS DE INFORMACIÓN ---

class _HomeInfoCards extends ConsumerWidget {
  const _HomeInfoCards();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(homeSummaryDataProvider);
    final data = summaryAsync.value ?? (income: 0.0, expenses: 0.0, debts: 0.0, available: 0.0);
    
    // Obtenemos el Ahorro Real desde el provider existente
    final savings = ref.watch(currentSavingsProvider).value ?? 0.0;

    return Column(
      children: [
        // Fila 1: Ingresos y Gastos
        Row(
          children: [
            Expanded(
              child: _SolidSummaryCard(
                title: "Ingresos",
                amount: data.income,
                color: const Color(0xFF1DD1A1), // Esmeralda
                icon: FontAwesomeIcons.moneyBillTrendUp,
              ),
            ),
            const Gap(12),
            Expanded(
              child: _SolidSummaryCard(
                title: "Gastos Planif.",
                amount: data.expenses,
                color: const Color(0xFFFF6B6B), // Coral
                icon: FontAwesomeIcons.receipt,
              ),
            ),
          ],
        ),
        const Gap(12),
        // Fila 2: Deudas y Ahorro
        Row(
          children: [
            Expanded(
              child: _SolidSummaryCard(
                title: "Deudas",
                amount: data.debts,
                color: const Color(0xFFE17055), // Terracota
                icon: FontAwesomeIcons.fileInvoiceDollar,
              ),
            ),
            const Gap(12),
            Expanded(
              child: _SolidSummaryCard(
                title: "Ahorro",
                amount: savings,
                color: const Color(0xFF6C5CE7), // Púrpura Real
                icon: FontAwesomeIcons.piggyBank,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Nueva Tarjeta Sólida (Estilo Expenses)
class _SolidSummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SolidSummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 0);
    
    return Container(
      height: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(100),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: Colors.white70),
              const Gap(6),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Gap(8),
          Text(
            currencyFormat.format(amount),
            style: const TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.w900, 
              color: Colors.white
            ),
          ),
        ],
      ),
    );
  }
}