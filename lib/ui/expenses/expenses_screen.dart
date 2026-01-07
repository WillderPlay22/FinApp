import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:finapp/data/models/enums.dart';
import 'package:finapp/date_utils.dart';
import 'package:finapp/logic/providers/database_providers.dart';
import 'package:finapp/logic/providers/time_provider.dart';
import 'modals/add_expense_modal.dart';
import 'widgets/expense_history_list.dart';
import 'widgets/expenses_summary_header.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Añadimos un listener para reconstruir el estado y que el gráfico se actualice al cambiar de pestaña
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.removeListener(() {});
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Seleccionamos qué datos mostrar en el gráfico según la pestaña activa
    final chartData = _tabController.index == 0
        ? ref.watch(categoryChartDataProvider)
        : ref.watch(historyChartDataProvider);

    // Obtenemos los totales para las tarjetas de resumen
    final projectedTotalAsync = ref.watch(projectedTotalProvider);
    final executedTotalAsync = ref.watch(executedTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestión de Gastos"),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Categorías", icon: Icon(FontAwesomeIcons.layerGroup)),
            Tab(text: "Historial", icon: Icon(FontAwesomeIcons.clockRotateLeft)),
          ],
        ),
      ),
      body: Column(
        children: [
          ExpensesSummaryHeader(
            chartData: chartData,
            projectedTotal: projectedTotalAsync,
            executedTotal: executedTotalAsync,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [FixedExpensesList(), ExpenseHistoryList()],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true, builder: (ctx) => const AddExpenseModal()),
        label: const Text("Gasto Extra"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}