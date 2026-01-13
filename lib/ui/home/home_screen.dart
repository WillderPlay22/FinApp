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
import '../../data/models/saving.dart';
import '../../data/models/transaction.dart';
import '../../date_utils.dart';
import '../../logic/providers/database_providers.dart';
import '../../data/daos/debt_dao.dart';
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

// Transacciones Reales del Mes (Para cálculo de flujo de caja en planificación)
final monthRealTransactionsProvider = StreamProvider<List<FinancialTransaction>>((ref) async* {
  final expenseDao = ref.watch(expenseDaoProvider);
  final now = ref.watch(nowProvider);
  final range = getCycleDateRange(now, Frequency.monthly);
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
    return const SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        children: [
          Gap(10),
          _HomeChartSection(),
          Gap(30),
          _HomeInfoCards(),
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
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final debtDao = ref.watch(debtDaoProvider); // Necesitamos el DAO para calcular fechas

    for (var debt in debts) {
      // Usamos la fecha de próximo pago como ancla.
      DateTime? anchorDate = debt.nextPaymentDate;
      
      // 1. Generamos bloques futuros desde anchorDate
      if (anchorDate != null) {
        DateTime date = anchorDate;
        while (date.isBefore(endOfMonth) || date.isAtSameMomentAs(endOfMonth)) {
          // ID estable basado en el día: debt_ID_DIA
          final blockId = "debt_${debt.id}_${date.day}";
          
          blocks.add((
            id: blockId,
            name: debt.title,
            icon: FontAwesomeIcons.fileInvoiceDollar.codePoint,
            color: Colors.purple.shade700.value,
            amount: debt.installmentAmount,
            subtitle: "Vence: ${DateFormat('d MMM', 'es').format(date)}",
            isLocked: false,
            paidCount: null,
            totalCount: null,
          ));
          
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
            color: Colors.purple.shade700.value,
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
  final int totalColumns;
  final double income;
  final double totalExpenses;
  final double remaining;
  final List<dynamic> blocks; // Lista de bloques en esta columna
  final List<FinancialTransaction> allRealTransactions; // Todas las transacciones del mes
  final Function(String) onDrop;

  const _PlanningColumn({
    required this.index,
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
    final now = DateTime.now();

    // Título y Fechas Dinámicas
    String title = "";
    String dateRange = "";
    DateTime colStart;
    DateTime colEnd;

    if (totalColumns == 2) {
      // Lógica Quincenal
      if (index == 0) {
        title = "Pago Fin de Mes";
        dateRange = "Cubre: 1 - 15 ${DateFormat('MMM', 'es').format(now)}";
        colStart = DateTime(now.year, now.month, 1);
        colEnd = DateTime(now.year, now.month, 15, 23, 59, 59);
      } else {
        title = "Pago Quincena";
        dateRange = "Cubre: 16 - ${DateTime(now.year, now.month + 1, 0).day} ${DateFormat('MMM', 'es').format(now)}";
        colStart = DateTime(now.year, now.month, 16);
        colEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      }
    } else if (totalColumns == 4) {
      title = "Semana ${index + 1}";
      dateRange = ""; // Simplificado para semanal
      // Cálculo aproximado de semanas
      colStart = DateTime(now.year, now.month, 1).add(Duration(days: index * 7));
      colEnd = colStart.add(const Duration(days: 6, hours: 23, minutes: 59));
    } else {
      title = "Mes Completo";
      dateRange = DateFormat('MMMM', 'es').format(now);
      colStart = DateTime(now.year, now.month, 1);
      colEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
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
        final matchKey = categoryBlockPool.keys.firstWhere(
          (k) => true, // Difícil coincidir por ID sin cargar la relación.
          orElse: () => -1
        );
        
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
                      color: realRemaining >= 0 ? Colors.teal : Colors.red,
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

class _HomeChartSection extends ConsumerWidget {
  const _HomeChartSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Usamos los totales proyectados para mostrar la disponibilidad teórica del mes
    final incomeAsync = ref.watch(incomeProjectedTotalProvider);
    final expensesAsync = ref.watch(projectedTotalProvider); // De expenses_screen.dart
    
    final projectedIncome = incomeAsync.value ?? 0.0;
    final projectedExpenses = expensesAsync.value ?? 0.0;
    
    // Calculamos el restante (Disponible)
    final remaining = (projectedIncome - projectedExpenses).clamp(0.0, double.infinity);
    
    // Si no hay datos, mostramos estado vacío
    if (projectedIncome == 0 && projectedExpenses == 0) {
       return SizedBox(
         height: 220, 
         child: Center(child: Text("Sin datos para proyectar", style: TextStyle(color: Theme.of(context).colorScheme.outline)))
       );
    }

    // Secciones del gráfico
    final sections = [
      // Sección de Gastos (Rojo)
      if (projectedExpenses > 0)
        PieChartSectionData(
          value: projectedExpenses,
          color: Colors.red.shade400,
          radius: 25,
          showTitle: false,
        ),
      // Sección de Disponible (Verde)
      if (remaining > 0)
        PieChartSectionData(
          value: remaining,
          color: Colors.green.shade400,
          radius: 25,
          showTitle: false,
        ),
    ];

    final currencyFormat = NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 0);

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
              Text(
                currencyFormat.format(remaining),
                style: TextStyle(
                  fontSize: 32, 
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -1,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

// --- TARJETAS DE INFORMACIÓN ---

class _HomeInfoCards extends ConsumerWidget {
  const _HomeInfoCards();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Datos de Ingresos
    final incomeExecuted = ref.watch(incomeExecutedTotalProvider).value ?? 0.0;
    final incomeProjected = ref.watch(incomeProjectedTotalProvider).value ?? 0.0;

    // 2. Datos de Pagos Fijos
    final fixedStatus = ref.watch(fixedPaymentsStatusProvider).value ?? (paid: 0, total: 0);

    // 3. Datos de Deudas
    final debtPaid = ref.watch(debtPaidTotalProvider).value ?? 0.0;
    final debtPending = ref.watch(debtPendingTotalProvider).value ?? 0.0;

    // 4. Datos de Ahorro
    final savings = ref.watch(currentSavingsProvider).value ?? 0.0;

    return Column(
      children: [
        // Fila 1: Ingresos y Ahorro
        Row(
          children: [
            Expanded(
              child: _InfoCard(
                title: "Ingresos",
                icon: FontAwesomeIcons.moneyBillTrendUp,
                color: Colors.teal,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ValueRow("Percibido", incomeExecuted),
                    const Gap(4),
                    _ValueRow("Proyectado", incomeProjected, isSecondary: true),
                  ],
                ),
              ),
            ),
            const Gap(12),
            Expanded(
              child: _InfoCard(
                title: "Ahorro Actual",
                icon: FontAwesomeIcons.piggyBank,
                color: Colors.amber.shade700,
                content: Center(
                  child: Text(
                    NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 0).format(savings),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ),
            ),
          ],
        ),
        const Gap(12),
        // Fila 2: Pagos Fijos y Deudas
        Row(
          children: [
            Expanded(
              child: _InfoCard(
                title: "Pagos Fijos",
                icon: FontAwesomeIcons.calendarCheck,
                color: Colors.blue.shade700,
                content: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          "${fixedStatus.paid}",
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "/${fixedStatus.total}",
                          style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.outline),
                        ),
                      ],
                    ),
                    const Text("Realizados", style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const Gap(12),
            Expanded(
              child: _InfoCard(
                title: "Deudas",
                icon: FontAwesomeIcons.fileInvoiceDollar,
                color: Colors.purple.shade700,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ValueRow("Pagado", debtPaid),
                    const Gap(4),
                    _ValueRow("Pendiente", debtPending, isSecondary: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


// Widget base para las tarjetas
class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget content;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 135,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        // Sombra suave para dar profundidad
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.03).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la tarjeta con icono y título
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha((255 * 0.1).round()),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const Gap(8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.outline, 
                    fontWeight: FontWeight.w600
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Contenido dinámico
          content,
          const Spacer(),
        ],
      ),
    );
  }
}

// Widget auxiliar para filas de valores (Etiqueta + Monto)
class _ValueRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isSecondary;

  const _ValueRow(this.label, this.amount, {this.isSecondary = false});

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.compactCurrency(locale: 'es', symbol: '\$', decimalDigits: 1);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: isSecondary ? Colors.grey : null)),
        Text(
          format.format(amount),
          style: TextStyle(
            fontSize: isSecondary ? 12 : 15,
            fontWeight: isSecondary ? FontWeight.normal : FontWeight.bold,
            color: isSecondary ? Colors.grey : null,
          ),
        ),
      ],
    );
  }
}