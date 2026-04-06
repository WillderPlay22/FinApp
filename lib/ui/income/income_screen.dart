import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:isar/isar.dart';
import 'package:finapp/data/local_db/isar_db.dart';
import 'package:finapp/data/models/enums.dart';
import 'package:finapp/date_utils.dart';
import 'package:finapp/logic/providers/time_provider.dart';
import 'package:finapp/data/models/recurring_movement.dart';
import 'package:finapp/data/models/transaction.dart';
import 'widgets/income_summary_header.dart';
import 'widgets/fixed_income_list.dart';
import 'widgets/income_history_list.dart';
import 'modals/add_income_modal.dart';
import '../../config/theme/app_colors.dart';

// --- PROVIDERS PARA EL RESUMEN DE INGRESOS ---

// Provider local para el rango de fechas del historial en Ingresos
final historyDateRangeProvider = StateProvider<DateRange>((ref) {
  final now = ref.watch(nowProvider);
  return getCycleDateRange(now, Frequency.monthly);
});

// Total Proyectado (Suma de todos los ingresos fijos activos)
final incomeProjectedTotalProvider = StreamProvider<double>((ref) async* {
  final isar = await IsarService().db;
  yield* isar.recurringMovements
      .where()
      .watch(fireImmediately: true)
      .map((movements) {
    // Sumamos los montos configurados (ej: si es quincenal, suma los 2 pagos)
    return movements.fold(0.0,
        (sum, m) => sum + (m.paymentAmounts ?? []).fold(0.0, (s, e) => s + e));
  });
});

// Total Ejecutado (Suma de transacciones de tipo ingreso en el mes actual)
final incomeExecutedTotalProvider = StreamProvider<double>((ref) async* {
  final isar = await IsarService().db;
  final now = ref.watch(nowProvider);
  final range = getCycleDateRange(now, Frequency.monthly);

  yield* isar.financialTransactions
      .filter()
      .typeEqualTo(TransactionType.income)
      .dateBetween(range.start, range.end)
      .watch(fireImmediately: true)
      .map((txs) => txs.fold(0.0, (sum, tx) => sum + tx.amount));
});

// Total Ejecutado de SOLO FIJOS (para el cálculo correcto del gráfico)
final incomeFixedExecutedTotalProvider = StreamProvider<double>((ref) async* {
  final isar = await IsarService().db;
  final now = ref.watch(nowProvider);
  final range = getCycleDateRange(now, Frequency.monthly);

  yield* isar.financialTransactions
      .filter()
      .typeEqualTo(TransactionType.income)
      .dateBetween(range.start, range.end)
      .parentRecurringIdIsNotNull() // Solo los que vienen de un ingreso recurrente
      .watch(fireImmediately: true)
      .map((txs) => txs.fold(0.0, (sum, tx) => sum + tx.amount));
});

// Total Histórico (Suma de transacciones de tipo ingreso en el rango seleccionado del historial)
final incomeHistoryTotalProvider = Provider<AsyncValue<double>>((ref) {
  // Reutilizamos el provider que ya existe para el historial de gastos,
  // pero aquí asumimos que se creará uno similar para ingresos o usamos la lógica directa.
  // Por simplicidad y robustez, consultamos directamente el rango del historial.
  final range = ref.watch(historyDateRangeProvider);
  return ref.watch(incomeExecutedInDateRangeProvider(range));
});

// Helper para historial
final incomeExecutedInDateRangeProvider =
    StreamProvider.family<double, DateRange>((ref, range) async* {
  final isar = await IsarService().db;
  yield* isar.financialTransactions
      .filter()
      .typeEqualTo(TransactionType.income)
      .dateBetween(range.start, range.end)
      .watch(fireImmediately: true)
      .map((txs) => txs.fold(0.0, (sum, tx) => sum + tx.amount));
});

// Datos del Gráfico (Cobrado vs Por Cobrar)
final incomeChartDataProvider =
    Provider<AsyncValue<Map<String, ({double total, int color})>>>((ref) {
  final projectedAsync = ref.watch(incomeProjectedTotalProvider);
  final executedAsync = ref.watch(incomeExecutedTotalProvider);
  final fixedExecutedAsync = ref.watch(incomeFixedExecutedTotalProvider);

  if (projectedAsync.isLoading ||
      executedAsync.isLoading ||
      fixedExecutedAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final projected = projectedAsync.value ?? 0.0;
  final executed = executedAsync.value ?? 0.0;
  final fixedExecuted = fixedExecutedAsync.value ?? 0.0;

  // Calculamos lo que falta por cobrar basándonos SOLO en (Proyectado - Lo que ya cobraste de fijos).
  // Así, los ingresos extras no "comen" visualmente la parte que te falta por cobrar de tu sueldo/alquiler.
  final remaining = (projected - fixedExecuted).clamp(0.0, double.infinity);

  return AsyncValue.data({
    "Cobrado": (total: executed, color: const Color(0xFF05D5AA).toARGB32()),
    "Por Cobrar": (total: remaining, color: const Color(0xFF48DBFB).toARGB32()),
  });
});

class IncomeScreen extends ConsumerStatefulWidget {
  const IncomeScreen({super.key});

  @override
  ConsumerState<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends ConsumerState<IncomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final VoidCallback _tabListener;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabListener = () => setState(() {});
    _tabController.addListener(_tabListener);
  }

  @override
  void dispose() {
    _tabController.removeListener(_tabListener);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = _tabController.index;

    // Selección de datos según pestaña
    final chartData = ref.watch(incomeChartDataProvider);
    final projectedTotal = ref.watch(incomeProjectedTotalProvider);
    final executedTotal = ref.watch(incomeExecutedTotalProvider);
    final historyTotal = ref.watch(incomeHistoryTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Ingresos"),
        centerTitle: true,
        bottom: TabBar(
          key: const ValueKey('income_tab_bar'),
          controller: _tabController,
          tabs: const [
            Tab(text: "Mis Fijos", icon: Icon(FontAwesomeIcons.fileContract)),
            Tab(
                text: "Historial",
                icon: Icon(FontAwesomeIcons.clockRotateLeft)),
          ],
        ),
      ),
      body: Column(
        children: [
          IncomeSummaryHeader(
            tabIndex: tabIndex,
            chartData: chartData,
            projectedTotal: projectedTotal,
            executedTotal: executedTotal,
            historyTotal: historyTotal,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                FixedIncomeList(),
                IncomeHistoryList(),
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
        child: tabIndex == 0
            ? FloatingActionButton.extended(
                key: const ValueKey('fab_income'),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (context) => const AddIncomeModal(),
                  );
                },
                label: const Text("Ingreso"),
                icon: const Icon(FontAwesomeIcons.plus),
                backgroundColor: AppColors.of(context).incomeColor,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
