import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:finapp/data/models/enums.dart';
import 'package:finapp/date_utils.dart';
import 'package:finapp/logic/providers/database_providers.dart';
import 'package:finapp/logic/providers/time_provider.dart';
import 'modals/add_expense_modal.dart';
import 'modals/add_debt_modal.dart'; // Importar el nuevo modal de deudas
import 'widgets/expense_history_list.dart';
import 'widgets/expenses_summary_header.dart';
import 'widgets/debts_list.dart'; // Importar la nueva pantalla de deudas
import 'widgets/fixed_expenses_list.dart';

// --- PROVIDERS ESPECÍFICOS PARA ESTA PANTALLA ---

// Providers para los streams de datos del DAO, para que puedan ser combinados.
// ✅ CORREGIDO: Se cambia la implementación para mover la lógica de transformación
// del DAO al provider. Esto mejora la separación de responsabilidades y evita
// el error que causaba la carga infinita.
final _categorizedFixedProjectionProvider = StreamProvider<Map<String, ({double total, int color})>>((ref) {
  final expenseDao = ref.watch(expenseDaoProvider);
  // 1. Observamos la lista "cruda" de gastos fijos.
  return expenseDao.watchFixedExpenses().map((fixedExpenses) {
    // 2. Transformamos la lista en el mapa que necesita el gráfico.
    final Map<String, ({double total, int color})> projectionMap = {};
    for (final expense in fixedExpenses) {
      final category = expense.category.value;
      if (category == null) continue;
      final monthlyAmount = expenseDao.getMonthlyAmount(expense);
      final current = projectionMap[category.name] ?? (total: 0.0, color: category.colorValue);
      projectionMap[category.name] = (total: current.total + monthlyAmount, color: category.colorValue);
    }
    return projectionMap;
  });
});

final _categorizedExtrasInDateRangeProvider = StreamProvider.family<Map<String, ({double total, int color})>, DateRange>((ref, range) {
  return ref.watch(expenseDaoProvider).watchCategorizedExtrasInDateRange(range);
});

// Provider para los datos del gráfico de la pestaña "Categorías" (Proyección)
final categoryChartDataProvider = Provider<AsyncValue<Map<String, ({double total, int color})>>>((ref) {
  final now = ref.watch(nowProvider);
  final monthRange = getCycleDateRange(now, Frequency.monthly);

  // Observamos los providers de stream intermedios
  final fixedAsync = ref.watch(_categorizedFixedProjectionProvider);
  final extrasAsync = ref.watch(_categorizedExtrasInDateRangeProvider(monthRange));

  // Combinar los datos de gastos fijos proyectados y gastos extras del mes
  // Ahora 'fixedAsync' y 'extrasAsync' son AsyncValue, por lo que esta lógica es correcta.
  if (fixedAsync.isLoading || extrasAsync.isLoading) return const AsyncValue.loading();
  if (fixedAsync.hasError) return AsyncValue.error(fixedAsync.error!, fixedAsync.stackTrace!);
  if (extrasAsync.hasError) return AsyncValue.error(extrasAsync.error!, extrasAsync.stackTrace!);

  final fixedData = fixedAsync.value ?? {};
  final extrasData = extrasAsync.value ?? {};
  final combined = {...fixedData};
  extrasData.forEach((key, value) {
    combined.update(key, (existing) => (total: existing.total + value.total, color: existing.color), ifAbsent: () => value);
  });
  return AsyncValue.data(combined);
});

// Provider para los datos del gráfico de la pestaña "Historial" (Ejecutado)
final historyChartDataProvider = StreamProvider<Map<String, ({double total, int color})>>((ref) {
  final range = ref.watch(historyDateRangeProvider);
  return ref.watch(expenseDaoProvider).watchCategorizedSummaryInDateRange(range);
});

// Provider para el total del historial (Ejecutado en un rango)
final historyTotalProvider = Provider<AsyncValue<double>>((ref) {
  // Reutilizamos el provider del gráfico del historial para ser eficientes
  final historyChartAsync = ref.watch(historyChartDataProvider);

  // Cuando el provider del gráfico tenga datos, los sumamos.
  return historyChartAsync.when(
    data: (data) => AsyncValue.data(data.values.fold(0.0, (sum, e) => sum + e.total)),
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

// Providers para los totales, definidos fuera del build para eficiencia.
// ✅ CORREGIDO: Se reemplaza el StreamProvider ineficiente por un Provider que combina streams existentes.
// Esto evita recálculos innecesarios y soluciona el problema de la carga infinita.
final projectedTotalProvider = Provider<AsyncValue<double>>((ref) {
  // Reutilizamos los mismos providers que usa el gráfico para ser eficientes.
  final fixedProjectionAsync = ref.watch(_categorizedFixedProjectionProvider);
  final now = ref.watch(nowProvider);
  final monthRange = getCycleDateRange(now, Frequency.monthly);
  final extrasAsync = ref.watch(_categorizedExtrasInDateRangeProvider(monthRange));

  // Manejamos los estados de carga y error.
  if (fixedProjectionAsync.isLoading || extrasAsync.isLoading) return const AsyncValue.loading();
  if (fixedProjectionAsync.hasError) return AsyncValue.error(fixedProjectionAsync.error!, fixedProjectionAsync.stackTrace!);
  if (extrasAsync.hasError) return AsyncValue.error(extrasAsync.error!, extrasAsync.stackTrace!);

  // Sumamos los totales de ambos streams.
  final fixedTotal = fixedProjectionAsync.value?.values.fold<double>(0.0, (sum, e) => sum + e.total) ?? 0.0;
  final extrasTotal = extrasAsync.value?.values.fold<double>(0.0, (sum, e) => sum + e.total) ?? 0.0;

  return AsyncValue.data(fixedTotal + extrasTotal);
});

final executedTotalProvider = StreamProvider<double>((ref) {
  return ref.watch(expenseDaoProvider).watchTotalExecutedThisMonth();
});

// --- WIDGET DE LA PANTALLA ---

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  // Se guarda la función del listener para poder removerla correctamente en el dispose.
  late final VoidCallback _tabListener;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Cambiado a 3 pestañas
    // Se define y añade el listener.
    _tabListener = () => setState(() {});
    _tabController.addListener(_tabListener);
  }

  @override
  void dispose() {
    // Se remueve el listener específico que se añadió.
    _tabController.removeListener(_tabListener);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = _tabController.index;

    // Lógica para determinar qué datos mostrar en el header según la pestaña
    final AsyncValue<Map<String, ({double total, int color})>> chartData;
    if (tabIndex == 0) {
      chartData = ref.watch(categoryChartDataProvider);
    } else if (tabIndex == 2) {
      chartData = ref.watch(historyChartDataProvider);
    } else {
      chartData = const AsyncValue.data({}); // Placeholder para Deudas
    }

    final projectedTotalAsync = (tabIndex == 1) ? const AsyncValue.data(0.0) : ref.watch(projectedTotalProvider);
    final executedTotalAsync = (tabIndex == 1) ? const AsyncValue.data(0.0) : ref.watch(executedTotalProvider);
    final historyTotalAsync = (tabIndex == 1) ? const AsyncValue.data(0.0) : ref.watch(historyTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestión de Gastos"),
        centerTitle: true,
        bottom: TabBar(
          // ✅ Se añade un key para que Flutter sepa que el TabBar en sí no cambia
          key: const ValueKey('expenses_tab_bar'),
          controller: _tabController,
          tabs: const [ // Se añade la pestaña de Deudas
            Tab(text: "Categorías", icon: Icon(FontAwesomeIcons.layerGroup)),
            Tab(text: "Deudas", icon: Icon(FontAwesomeIcons.fileInvoiceDollar)),
            Tab(text: "Historial", icon: Icon(FontAwesomeIcons.clockRotateLeft)),
          ],
        ),
      ),
      body: Column(
        children: [
          ExpensesSummaryHeader(
            tabIndex: tabIndex, // Se pasa el índice de la pestaña
            chartData: chartData,
            projectedTotal: projectedTotalAsync,
            executedTotal: executedTotalAsync,
            historyTotal: historyTotalAsync,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [ // Se añade la vista de Deudas
                FixedExpensesList(), 
                DebtsList(), 
                ExpenseHistoryList()
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: _buildFabForTab(tabIndex),
      ),
    );
  }

  Widget _buildFabForTab(int index) {
    switch (index) {
      case 0: // Pestaña "Categorías"
        return FloatingActionButton.extended(
          key: const ValueKey('fab_gasto'),
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (ctx) => const AddExpenseModal(),
          ),
          label: const Text("Gasto"),
          icon: const Icon(Icons.add),
          backgroundColor: Colors.red,
        );
      case 1: // Pestaña "Deudas"
        return FloatingActionButton.extended(
          key: const ValueKey('fab_deuda'),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (ctx) => const AddDebtModal(),
            );
          }, 
          label: const Text("Deuda"),
          icon: const Icon(Icons.add),
          backgroundColor: Colors.purple.shade700, // Color consistente con la tarjeta de deudas
        );
      case 2: // Pestaña "Historial"
      default:
        // Devuelve un widget vacío para que el botón desaparezca.
        return const SizedBox.shrink(key: ValueKey('fab_empty'));
    }
  }
}