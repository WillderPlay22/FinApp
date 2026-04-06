import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../data/models/enums.dart';
import '../../data/models/transaction.dart';
import '../../date_utils.dart';
import '../../logic/providers/database_providers.dart';
import '../../logic/providers/time_provider.dart';
import '../../logic/providers/currency_providers.dart';
import '../../config/theme/app_colors.dart';
import '../shared/icon_mapper.dart';
import '../widgets/month_year_picker.dart';
import 'planning_providers.dart';

class PlanningScreen extends ConsumerStatefulWidget {
  const PlanningScreen({super.key});

  @override
  ConsumerState<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends ConsumerState<PlanningScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _initialPageSet = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _initPageForCurrentPeriod(List<DateRange> ranges) {
    if (_initialPageSet) return; // Solo se ejecuta una vez
    _initialPageSet = true;

    final now = ref.read(nowProvider);
    int initialPage = 0;
    for (int i = 0; i < ranges.length; i++) {
      if (!now.isBefore(ranges[i].start) && !now.isAfter(ranges[i].end)) {
        initialPage = i;
        break;
      }
    }
    if (_currentPage != initialPage && _pageController.hasClients) {
      _pageController.jumpToPage(initialPage);
    }
    _currentPage = initialPage;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final configAsync = ref.watch(planningConfigProvider);
    final expensesAsync = ref.watch(allFixedExpensesProvider);
    final debtsAsync = ref.watch(planningDebtsProvider);
    final positions = ref.watch(planningPositionsProvider);
    final realTransactionsAsync = ref.watch(monthRealTransactionsProvider);
    final rangesAsync = ref.watch(dynamicPeriodRangesProvider);

    if (configAsync.isLoading ||
        expensesAsync.isLoading ||
        debtsAsync.isLoading ||
        realTransactionsAsync.isLoading ||
        rangesAsync.isLoading) {
      return Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          title: const Text("Planificación"),
          backgroundColor: colors.surface,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final config = configAsync.value ??
        (columns: 1, columnIncomes: [0.0], freq: Frequency.monthly);
    final expenses = expensesAsync.value ?? [];
    final debts = debtsAsync.value ?? [];
    final realTransactions = realTransactionsAsync.value ?? [];
    final rateValue = ref.watch(currentExchangeRateProvider).value?.rate;
    final planningDate = ref.watch(planningDateProvider);
    final ranges = rangesAsync.value ?? [];

    // Build blocks (same logic as before)
    final blocksData = _buildBlocks(
      context, config, expenses, debts, realTransactions, positions, planningDate, rateValue, ranges,
    );
    final blocks = blocksData.blocks;
    final forcedPositions = blocksData.forcedPositions;
    final lockedIds = blocksData.lockedIds;

    // Unassigned blocks
    final unassignedBlocks = blocks.where((b) {
      if (forcedPositions.containsKey(b.id)) return false;
      return positions[b.id] == null;
    }).toList();

    // Initialize page to current period (solo una vez)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_pageController.hasClients) return;
      _initPageForCurrentPeriod(ranges);
    });

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text("Planificación", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colors.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Date selector
          const _PlanningDateSelector(),
          const Gap(8),

          // Page indicator dots
          if (config.columns > 1) ...[
            _PageDots(
              count: config.columns,
              current: _currentPage,
              onTap: (i) {
                _pageController.animateToPage(i,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut);
              },
            ),
            const Gap(8),
          ],

          // Swipeable cards
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: config.columns,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, colIndex) {
                final columnBlocks = blocks.where((b) {
                  if (forcedPositions.containsKey(b.id)) {
                    return forcedPositions[b.id] == colIndex;
                  }
                  return positions[b.id] == colIndex;
                }).toList();

                double colIncome = config.columnIncomes.length > colIndex
                    ? config.columnIncomes[colIndex]
                    : 0.0;

                // Calculate real income for column
                colIncome = _calculateRealColumnIncome(
                  config, colIndex, colIncome, planningDate, realTransactions, rateValue, ranges,
                );

                final totalExpenses = columnBlocks.fold(0.0, (sum, b) => sum + b.amount);

                // Calculate real remaining
                final realRemaining = _calculateRealRemaining(
                  colIndex, config, planningDate, colIncome, totalExpenses,
                  columnBlocks, realTransactions, rateValue, ranges,
                );

                return _PlanningCard(
                  colIndex: colIndex,
                  totalColumns: config.columns,
                  planningDate: planningDate,
                  income: colIncome,
                  remaining: realRemaining,
                  blocks: columnBlocks,
                  ranges: ranges,
                  onDrop: (blockId) {
                    ref.read(planningPositionsProvider.notifier)
                        .updatePosition(blockId, colIndex);
                  },
                );
              },
            ),
          ),

          // Pool area
          _UnassignedPool(
            blocks: unassignedBlocks,
            onDropToPool: (blockId) {
              ref.read(planningPositionsProvider.notifier)
                  .updatePosition(blockId, null);
            },
          ),

          // Espacio para el nav bar flotante
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  double _calculateRealColumnIncome(
    ({int columns, List<double> columnIncomes, Frequency freq}) config,
    int colIndex,
    double projectedIncome,
    DateTime planningDate,
    List<FinancialTransaction> realTransactions,
    double? rateValue,
    List<DateRange> ranges,
  ) {
    if (ranges.isEmpty || colIndex >= ranges.length) return projectedIncome;

    final range = ranges[colIndex];

    // Find income transactions that fall within this range (or close to start)
    final matchingIncomeTx = realTransactions.where((tx) =>
        tx.type == TransactionType.income &&
        tx.isRecurring &&
        tx.parentRecurringId != null &&
        !tx.date.isBefore(range.start.subtract(const Duration(days: 3))) &&
        !tx.date.isAfter(range.end)).toList();

    if (matchingIncomeTx.isNotEmpty) {
      return matchingIncomeTx.fold(0.0, (sum, tx) => sum + tx.referenceAmountWithRate(rateValue));
    }
    return projectedIncome;
  }

  double _calculateRealRemaining(
    int colIndex,
    ({int columns, List<double> columnIncomes, Frequency freq}) config,
    DateTime planningDate,
    double income,
    double totalExpenses,
    List<_BlockData> columnBlocks,
    List<FinancialTransaction> realTransactions,
    double? rateValue,
    List<DateRange> ranges,
  ) {
    DateTime colStart, colEnd;
    if (ranges.isNotEmpty && colIndex < ranges.length) {
      colStart = ranges[colIndex].start;
      colEnd = ranges[colIndex].end;
    } else {
      colStart = DateTime(planningDate.year, planningDate.month, 1);
      colEnd = DateTime(planningDate.year, planningDate.month + 1, 0, 23, 59, 59);
    }

    final colTransactions = realTransactions.where((t) =>
        t.date.isAfter(colStart.subtract(const Duration(seconds: 1))) &&
        t.date.isBefore(colEnd.add(const Duration(seconds: 1)))).toList();

    final realTotalSpent = colTransactions
        .where((t) => t.type == TransactionType.expense || t.type == TransactionType.saving)
        .fold(0.0, (sum, t) => sum + t.referenceAmountWithRate(rateValue));

    final realExtraIncome = colTransactions
        .where((t) => t.type == TransactionType.income && !t.isRecurring)
        .fold(0.0, (sum, t) => sum + t.referenceAmountWithRate(rateValue));

    double matchedProjectedAmount = 0.0;

    for (var tx in colTransactions) {
      if (tx.isRecurring && tx.type == TransactionType.expense) {
        matchedProjectedAmount += tx.referenceAmountWithRate(rateValue);
      }
      if (tx.relatedDebt.value != null) {
        matchedProjectedAmount += tx.referenceAmountWithRate(rateValue);
      }
    }

    if (matchedProjectedAmount > totalExpenses) {
      matchedProjectedAmount = totalExpenses;
    }

    return (income + realExtraIncome) - realTotalSpent - (totalExpenses - matchedProjectedAmount);
  }

  _BlocksBuildResult _buildBlocks(
    BuildContext context,
    ({int columns, List<double> columnIncomes, Frequency freq}) config,
    List<dynamic> expenses,
    List<dynamic> debts,
    List<FinancialTransaction> realTransactions,
    Map<String, int?> positions,
    DateTime planningDate,
    double? rateValue,
    List<DateRange> ranges,
  ) {
    final List<_BlockData> blocks = [];
    final Map<String, int> forcedPositions = {};
    final Set<String> lockedIds = {};

    // 1. Fixed expenses
    // Contar pagos por expense en el mes (para saber cuántos bloques marcar como pagados)
    final Map<int, int> paidCountPerExpense = {};
    for (var t in realTransactions) {
      if (t.relatedExpense.value != null &&
          t.date.year == planningDate.year &&
          t.date.month == planningDate.month) {
        final eid = t.relatedExpense.value!.id;
        paidCountPerExpense[eid] = (paidCountPerExpense[eid] ?? 0) + 1;
      }
    }

    for (var e in expenses) {
      final cat = e.category.value;
      if (cat == null) continue;

      final expAmount = (rateValue != null && e.currencyCode == 'BS')
          ? e.amount / rateValue
          : e.amount;

      int blocksCount = 1;
      if (e.frequency == Frequency.weekly) blocksCount = 4;
      if (e.frequency == Frequency.biweekly) blocksCount = 2;

      final totalPaid = paidCountPerExpense[e.id] ?? 0;

      for (int i = 0; i < blocksCount; i++) {
        blocks.add(_BlockData(
          id: "exp_${e.id}_$i",
          name: cat.name,
          paymentName: e.title,
          icon: cat.iconCode,
          color: cat.colorValue,
          amount: expAmount,
          subtitle: blocksCount > 1 ? "Parte ${i + 1}" : null,
          isLocked: false,
          paidCount: i < totalPaid ? 1 : 0,
          totalCount: 1,
          expenseId: e.id,
        ));
      }
    }

    // 2. Debts
    final startOfMonth = DateTime(planningDate.year, planningDate.month, 1);
    final endOfMonth = DateTime(planningDate.year, planningDate.month + 1, 0, 23, 59, 59);
    final debtDao = ref.watch(debtDaoProvider);

    for (var debt in debts) {
      DateTime? anchorDate = debt.nextPaymentDate;
      int remainingInstallments = 999;
      if (debt.installmentAmount > 0) {
        remainingInstallments = (debt.remainingAmount / debt.installmentAmount).ceil();
      }

      if (anchorDate != null && !debt.isPaidOff && remainingInstallments > 0) {
        DateTime date = anchorDate;

        while (date.isBefore(endOfMonth) || date.isAtSameMomentAs(endOfMonth)) {
          if (date.isAfter(startOfMonth.subtract(const Duration(seconds: 1)))) {
            blocks.add(_BlockData(
              id: "debt_${debt.id}_${date.day}",
              name: debt.title,
              paymentName: null,
              icon: FontAwesomeIcons.fileInvoiceDollar.codePoint,
              color: AppColors.of(context).debtColor.toARGB32(),
              amount: debt.installmentAmount,
              subtitle: "Vence: ${DateFormat('d MMM', 'es').format(date)}",
              isLocked: false,
              paidCount: null,
              totalCount: null,
              expenseId: null,
            ));
            remainingInstallments--;
            if (remainingInstallments <= 0) break;
          } else {
            remainingInstallments--;
            if (remainingInstallments <= 0) break;
          }
          date = debtDao.calculateNextPaymentDate(date, debt.frequency, debt.customDays);
        }
      }
    }

    // 3. Real world override (lock paid blocks)
    int getColumnForDate(DateTime date) {
      for (int i = 0; i < ranges.length; i++) {
        if (!date.isBefore(ranges[i].start) && !date.isAfter(ranges[i].end)) {
          return i;
        }
      }
      // Fallback
      if (config.columns == 4) return ((date.day - 1) / 7).floor().clamp(0, 3);
      return 0;
    }

    for (var tx in realTransactions) {
      if (tx.date.year != planningDate.year || tx.date.month != planningDate.month) continue;

      if (tx.relatedDebt.value != null) {
        final debt = tx.relatedDebt.value!;
        final colIndex = getColumnForDate(tx.date);
        final debtPrefix = "debt_${debt.id}_";

        int existingIndex = blocks.indexWhere((b) => b.id == "debt_${debt.id}_${tx.date.day}");
        if (existingIndex == -1) {
          existingIndex = blocks.indexWhere((b) => b.id.startsWith(debtPrefix) && !b.isLocked);
        }

        if (existingIndex != -1) {
          blocks[existingIndex] = blocks[existingIndex].copyWith(
            subtitle: "Pagado el ${tx.date.day}",
            isLocked: true,
          );
          forcedPositions[blocks[existingIndex].id] = colIndex;
          lockedIds.add(blocks[existingIndex].id);
        } else {
          final blockId = "debt_${debt.id}_${tx.date.day}";
          blocks.add(_BlockData(
            id: blockId,
            name: debt.title,
            paymentName: null,
            icon: FontAwesomeIcons.fileInvoiceDollar.codePoint,
            color: AppColors.of(context).debtColor.toARGB32(),
            amount: tx.referenceAmountWithRate(rateValue),
            subtitle: "Pagado el ${tx.date.day}",
            isLocked: true,
            paidCount: null,
            totalCount: null,
            expenseId: null,
          ));
          forcedPositions[blockId] = colIndex;
          lockedIds.add(blockId);
        }
      } else if (tx.isRecurring && tx.relatedExpense.value != null) {
        final expense = tx.relatedExpense.value!;
        final colIndex = getColumnForDate(tx.date);
        final expPrefix = "exp_${expense.id}_";

        final blockIndex = blocks.indexWhere(
            (b) => b.id.startsWith(expPrefix) && !lockedIds.contains(b.id));

        if (blockIndex != -1) {
          final block = blocks[blockIndex];
          blocks[blockIndex] = block.copyWith(
            amount: tx.referenceAmountWithRate(rateValue),
            subtitle: "Pagado: \$${tx.referenceAmountWithRate(rateValue).toStringAsFixed(0)}",
            isLocked: true,
          );
          forcedPositions[block.id] = colIndex;
          lockedIds.add(block.id);
        }
      }
    }

    return _BlocksBuildResult(blocks: blocks, forcedPositions: forcedPositions, lockedIds: lockedIds);
  }
}

// --- DATA CLASSES ---

class _BlockData {
  final String id;
  final String name;
  final String? paymentName;
  final int icon;
  final int color;
  final double amount;
  final String? subtitle;
  final bool isLocked;
  final int? paidCount;
  final int? totalCount;
  final int? expenseId;

  const _BlockData({
    required this.id,
    required this.name,
    this.paymentName,
    required this.icon,
    required this.color,
    required this.amount,
    this.subtitle,
    this.isLocked = false,
    this.paidCount,
    this.totalCount,
    this.expenseId,
  });

  _BlockData copyWith({
    double? amount,
    String? subtitle,
    bool? isLocked,
  }) {
    return _BlockData(
      id: id,
      name: name,
      paymentName: paymentName,
      icon: icon,
      color: color,
      amount: amount ?? this.amount,
      subtitle: subtitle ?? this.subtitle,
      isLocked: isLocked ?? this.isLocked,
      paidCount: paidCount,
      totalCount: totalCount,
      expenseId: expenseId,
    );
  }
}

class _BlocksBuildResult {
  final List<_BlockData> blocks;
  final Map<String, int> forcedPositions;
  final Set<String> lockedIds;

  const _BlocksBuildResult({
    required this.blocks,
    required this.forcedPositions,
    required this.lockedIds,
  });
}

// --- PAGE DOTS ---

class _PageDots extends StatelessWidget {
  final int count;
  final int current;
  final Function(int) onTap;

  const _PageDots({required this.count, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return GestureDetector(
          onTap: () => onTap(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? colors.primary : colors.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}

// --- PLANNING CARD (Swipeable page) ---

class _PlanningCard extends StatelessWidget {
  final int colIndex;
  final int totalColumns;
  final DateTime planningDate;
  final double income;
  final double remaining;
  final List<_BlockData> blocks;
  final List<DateRange> ranges;
  final Function(String) onDrop;

  const _PlanningCard({
    required this.colIndex,
    required this.totalColumns,
    required this.planningDate,
    required this.income,
    required this.remaining,
    required this.blocks,
    required this.ranges,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final appColors = AppColors.of(context);

    String title = "";
    String dateRange = "";

    if (totalColumns == 2 && ranges.length == 2) {
      final range = ranges[colIndex];
      final monthFmt = DateFormat('MMM', 'es');
      if (colIndex == 0) {
        title = "Pago Quincena";
      } else {
        title = "Pago Fin de Mes";
      }
      // Mostrar ambos meses cuando el rango cruza meses
      if (range.isCrossMonth) {
        dateRange = "Cubre: ${range.start.day} ${monthFmt.format(range.start)} - ${range.end.day} ${monthFmt.format(range.end)}";
      } else {
        dateRange = "Cubre: ${range.start.day} - ${range.end.day} ${monthFmt.format(range.start)}";
      }
    } else if (totalColumns == 4 && ranges.length == 4) {
      title = "Semana ${colIndex + 1}";
      final range = ranges[colIndex];
      dateRange = "${range.start.day} - ${range.end.day} ${DateFormat('MMM', 'es').format(planningDate)}";
    } else {
      title = DateFormat('MMMM yyyy', 'es').format(planningDate);
      dateRange = "Mes completo";
    }

    final currencyFormat = NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 0);

    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isHovered ? colors.primaryContainer.withAlpha(30) : colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isHovered ? colors.primary : colors.outlineVariant.withAlpha(80),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                            fontSize: 16)),
                    Text(dateRange,
                        style: TextStyle(fontSize: 11, color: colors.outline)),
                    const Gap(12),
                    // Big remaining number
                    Text("Disponible",
                        style: TextStyle(fontSize: 12, color: colors.outline)),
                    const Gap(4),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: remaining, end: remaining),
                      duration: const Duration(milliseconds: 600),
                      builder: (context, val, _) {
                        return Text(
                          currencyFormat.format(val),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: remaining >= 0 ? appColors.success : appColors.error,
                            letterSpacing: -1,
                          ),
                        );
                      },
                    ),
                    const Gap(4),
                    Text(
                      "Ingreso: ${currencyFormat.format(income)}",
                      style: TextStyle(fontSize: 11, color: colors.outline),
                    ),
                  ],
                ),
              ),

              // Blocks grid
              Expanded(
                child: blocks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.drag_indicator, size: 32, color: colors.outlineVariant),
                            const Gap(8),
                            Text("Arrastra gastos aquí",
                                style: TextStyle(color: colors.outline, fontSize: 13)),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: blocks.map((b) => _ExpenseBlock(data: b)).toList(),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- EXPENSE BLOCK ---

class _ExpenseBlock extends ConsumerWidget {
  final _BlockData data;

  const _ExpenseBlock({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockColor = Color(data.color);
    final blockIcon = getIconFromCode(data.icon);

    final bool showCounter = data.totalCount != null && data.totalCount! > 0;
    final bool allPaid = showCounter && data.paidCount == data.totalCount;

    final content = Container(
      width: 150,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: blockColor,
        borderRadius: BorderRadius.circular(14),
        border: data.isLocked || allPaid
            ? Border.all(color: Colors.greenAccent, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: blockColor.withAlpha(80),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(blockIcon, color: Colors.white, size: 14),
              if (data.isLocked || allPaid) ...[
                const Gap(4),
                const Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
              ],
              const Gap(6),
              Expanded(
                child: Text(
                  data.name,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (data.paymentName != null) ...[
            const Gap(2),
            Text(data.paymentName!,
                style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 9),
                overflow: TextOverflow.ellipsis),
          ],
          const Gap(6),
          Text(
            NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 0).format(data.amount),
            style: const TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          if (data.subtitle != null) ...[
            const Gap(2),
            Text(data.subtitle!,
                style: TextStyle(
                    color: Colors.white.withAlpha(200), fontSize: 9, fontStyle: FontStyle.italic)),
          ],
          if (data.isLocked) ...[
            const Gap(2),
            const Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.lock, color: Colors.white70, size: 10),
            ),
          ],
        ],
      ),
    );

    return InkWell(
      onTap: data.isLocked
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("Bloque bloqueado: pago ya realizado (${data.subtitle})."),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ));
            }
          : null,
      child: Draggable<String>(
        data: data.id,
        maxSimultaneousDrags: data.isLocked ? 0 : 1,
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(opacity: 0.9, child: SizedBox(width: 140, child: content)),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: content),
        child: content,
      ),
    );
  }
}

// --- UNASSIGNED POOL ---

class _UnassignedPool extends StatelessWidget {
  final List<_BlockData> blocks;
  final Function(String) onDropToPool;

  const _UnassignedPool({required this.blocks, required this.onDropToPool});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onDropToPool(details.data),
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return Container(
          height: 120,
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isHovered
                ? colors.primaryContainer.withAlpha(50)
                : colors.surfaceContainerHighest.withAlpha(80),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isHovered ? colors.primary : colors.outlineVariant.withAlpha(80)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Sin Asignar (${blocks.length})",
                style: TextStyle(
                    fontSize: 11, color: colors.outline, fontWeight: FontWeight.bold),
              ),
              const Gap(6),
              Expanded(
                child: blocks.isEmpty
                    ? Center(
                        child: Text("¡Todo planificado!",
                            style: TextStyle(fontSize: 11, color: colors.primary)))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: blocks.map((b) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _CompactBlock(data: b),
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CompactBlock extends StatelessWidget {
  final _BlockData data;

  const _CompactBlock({required this.data});

  @override
  Widget build(BuildContext context) {
    final blockColor = Color(data.color);
    final blockIcon = getIconFromCode(data.icon);

    final content = Container(
      width: 110,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: blockColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(blockIcon, color: Colors.white, size: 12),
              const Gap(4),
              Expanded(
                child: Text(data.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const Gap(4),
          Text(
            NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 0).format(data.amount),
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );

    return Draggable<String>(
      data: data.id,
      maxSimultaneousDrags: data.isLocked ? 0 : 1,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(opacity: 0.9, child: SizedBox(width: 110, child: content)),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: content),
      child: content,
    );
  }
}

// --- DATE SELECTOR ---

class _PlanningDateSelector extends ConsumerWidget {
  const _PlanningDateSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(planningDateProvider);
    final now = ref.watch(nowProvider);
    final rangesAsync = ref.watch(dynamicPeriodRangesProvider);
    final ranges = rangesAsync.valueOrNull ?? [];
    final hasCrossMonth = ranges.any((r) => r.isCrossMonth);

    bool isSameMonth(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month;

    final isThisMonth = isSameMonth(selectedDate, now);
    final nextMonthDate = DateTime(now.year, now.month + 1, 1);
    final isNextMonth = isSameMonth(selectedDate, nextMonthDate);
    final isOther = !isThisMonth && !isNextMonth;

    final thisMonthLabel = hasCrossMonth ? "Periodo Actual" : "Este Mes";
    final nextMonthLabel = hasCrossMonth ? "Sig. Periodo" : "Próximo Mes";

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildChip(context, ref, thisMonthLabel, isThisMonth,
              () => ref.read(planningDateProvider.notifier).state = now),
          const Gap(8),
          _buildChip(context, ref, nextMonthLabel, isNextMonth,
              () => ref.read(planningDateProvider.notifier).state = nextMonthDate),
          const Gap(8),
          _buildChip(
              context,
              ref,
              isOther
                  ? DateFormat('MMMM y', 'es').format(selectedDate).toUpperCase()
                  : "Otro Mes",
              isOther, () async {
            final picked = await showDialog<DateTime>(
              context: context,
              builder: (context) => MonthYearPicker(
                initialDate: isOther ? selectedDate : nextMonthDate,
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 5),
              ),
            );
            if (picked != null) {
              ref.read(planningDateProvider.notifier).state = picked;
            }
          }),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, WidgetRef ref, String label,
      bool isSelected, VoidCallback onTap) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? colors.primary : colors.outlineVariant.withAlpha(100)),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12)),
      ),
    );
  }
}
