import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../data/models/debt.dart';
import '../../data/models/enums.dart';
import '../../data/models/expense.dart';
import '../../data/models/saving.dart';
import '../../data/models/transaction.dart';
import '../../data/models/recurring_movement.dart';
import '../../date_utils.dart';
import '../../logic/providers/database_providers.dart';
import '../../logic/providers/time_provider.dart';
import '../../logic/providers/currency_providers.dart';
import '../../config/theme/app_colors.dart';
import '../expenses/expenses_screen.dart';
import '../income/income_screen.dart';
import '../planning/planning_providers.dart';
import 'models/upcoming_payment.dart';

// =============================================
//  PROVIDERS MIGRADOS DESDE home_screen.dart
// =============================================

enum SummaryFilter { currentPeriod, nextPeriod, currentMonth, nextMonth }

final summaryFilterProvider =
    StateProvider<SummaryFilter>((ref) => SummaryFilter.currentPeriod);

// Estado de Pagos Fijos (Pagados vs Totales en el mes actual)
final fixedPaymentsStatusProvider =
    StreamProvider<({int paid, int total})>((ref) async* {
  final expenseDao = ref.watch(expenseDaoProvider);
  final now = ref.watch(nowProvider);
  final range = getCycleDateRange(now, Frequency.monthly);
  final isar = await expenseDao.isarService.db;

  final query = isar.financialTransactions
      .filter()
      .typeEqualTo(TransactionType.expense)
      .isRecurringEqualTo(true)
      .dateBetween(range.start, range.end)
      .build();

  await for (final transactions in query.watch(fireImmediately: true)) {
    final fixedExpenses =
        await isar.expenses.filter().isRecurringEqualTo(true).findAll();
    final total = fixedExpenses.length;

    final paidIds = transactions
        .map((t) => t.relatedExpense.value?.id)
        .whereType<int>()
        .toSet();
    final paid = fixedExpenses.where((e) => paidIds.contains(e.id)).length;

    yield (paid: paid, total: total);
  }
});

// Balance de Ahorro Actual (Ingresos Ejecutados - Gastos Ejecutados)
final currentSavingsProvider = Provider<AsyncValue<double>>((ref) {
  final incomeAsync = ref.watch(incomeExecutedTotalProvider);
  final expenseAsync = ref.watch(executedTotalProvider);

  if (incomeAsync.isLoading || expenseAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final income = incomeAsync.value ?? 0.0;
  final expense = expenseAsync.value ?? 0.0;

  return AsyncValue.data(income - expense);
});

// Provider principal de datos del Home
final homeSummaryDataProvider = FutureProvider<
    ({
      double income,
      double expenses,
      double debts,
      double available
    })>((ref) async {
  final filter = ref.watch(summaryFilterProvider);
  final config = await ref.watch(planningConfigProvider.future);
  final expenses = await ref.watch(allFixedExpensesProvider.future);
  final allDebts = await ref.watch(planningDebtsProvider.future);
  final positions = ref.watch(planningPositionsProvider);
  final now = ref.read(nowProvider);
  final debtDao = ref.watch(debtDaoProvider);
  final expenseDao = ref.watch(expenseDaoProvider);
  final ranges = await ref.watch(dynamicPeriodRangesProvider.future);

  final exchangeRateService = ref.watch(exchangeRateServiceProvider);
  final currentRate = await exchangeRateService.getCurrentRate();
  final rateValue = currentRate?.rate;
  double toRef(double amount, String? currencyCode) {
    if (rateValue == null || currencyCode == null || currencyCode == 'USD') {
      return amount;
    }
    if (currencyCode == 'BS') return amount / rateValue;
    return amount;
  }

  int currentColumnIndex = 0;
  for (int i = 0; i < ranges.length; i++) {
    if (!now.isBefore(ranges[i].start) && !now.isAfter(ranges[i].end)) {
      currentColumnIndex = i;
      break;
    }
  }

  int? targetColumn;
  bool isNextMonth = false;
  bool isFullMonth = false;

  switch (filter) {
    case SummaryFilter.currentPeriod:
      targetColumn = currentColumnIndex;
      break;
    case SummaryFilter.nextPeriod:
      targetColumn = currentColumnIndex + 1;
      if (targetColumn! >= config.columns) {
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

  double income = 0.0;

  final viewDate = isNextMonth ? DateTime(now.year, now.month + 1, 1) : now;
  final isar = await expenseDao.isarService.db;

  DateTime periodStart, periodEnd;
  if (isFullMonth) {
    periodStart = DateTime(viewDate.year, viewDate.month, 1);
    periodEnd = DateTime(viewDate.year, viewDate.month + 1, 0, 23, 59, 59);
  } else if (targetColumn != null && targetColumn < ranges.length) {
    periodStart = ranges[targetColumn].start;
    periodEnd = ranges[targetColumn].end;
  } else {
    periodStart = DateTime(viewDate.year, viewDate.month, 1);
    periodEnd = DateTime(viewDate.year, viewDate.month + 1, 0, 23, 59, 59);
  }

  final confirmedIncomeTxs = await isar.financialTransactions
      .filter()
      .typeEqualTo(TransactionType.income)
      .isRecurringEqualTo(true)
      .parentRecurringIdIsNotNull()
      .dateBetween(
        periodStart.subtract(const Duration(days: 3)),
        periodEnd,
      )
      .findAll();

  double calculatedIncome = 0.0;

  if (confirmedIncomeTxs.isNotEmpty) {
    calculatedIncome += confirmedIncomeTxs.fold(
        0.0, (s, t) => s + t.referenceAmountWithRate(rateValue));
  } else {
    final recurringIncomes = await isar.recurringMovements
        .filter()
        .typeEqualTo(TransactionType.income)
        .findAll();

    for (var rec in recurringIncomes) {
      final pAmounts = rec.paymentAmounts ?? [];

      if (rec.frequency == Frequency.biweekly && config.columns == 2) {
        if (isFullMonth) {
          calculatedIncome +=
              pAmounts.fold(0.0, (s, a) => s + toRef(a, rec.currencyCode));
        } else if (targetColumn != null &&
            targetColumn < config.columnIncomes.length) {
          calculatedIncome += config.columnIncomes[targetColumn];
        }
      } else {
        final totalProjected = pAmounts.fold(0.0, (s, a) => s + a);

        if (isFullMonth) {
          calculatedIncome += toRef(totalProjected, rec.currencyCode);
        } else {
          calculatedIncome += toRef(totalProjected, rec.currencyCode);
        }
      }
    }
  }

  final extraIncomeTxs = await isar.financialTransactions
      .filter()
      .typeEqualTo(TransactionType.income)
      .isRecurringEqualTo(false)
      .dateBetween(periodStart, periodEnd)
      .findAll();

  calculatedIncome +=
      extraIncomeTxs.fold(0.0, (s, t) => s + t.referenceAmountWithRate(rateValue));

  income = calculatedIncome;

  double totalExpenses = 0.0;
  double totalDebts = 0.0;

  bool isColumnIncluded(int? colIndex) {
    if (isFullMonth) return true;
    return colIndex == targetColumn;
  }

  final expenseTransactions = await isar.financialTransactions
      .filter()
      .typeEqualTo(TransactionType.expense)
      .isRecurringEqualTo(true)
      .dateBetween(periodStart, periodEnd)
      .findAll();

  final Map<int, List<double>> paidExpenseAmounts = {};
  for (var tx in expenseTransactions) {
    await tx.relatedExpense.load();
    final expenseId = tx.relatedExpense.value?.id;
    if (expenseId != null) {
      paidExpenseAmounts.putIfAbsent(expenseId, () => []);
      paidExpenseAmounts[expenseId]!
          .add(tx.referenceAmountWithRate(rateValue));
    }
  }

  for (var expense in expenses) {
    int blocksCount = 1;
    if (expense.frequency == Frequency.weekly) blocksCount = 4;
    if (expense.frequency == Frequency.biweekly) blocksCount = 2;

    final paidAmounts = paidExpenseAmounts[expense.id] ?? [];
    int usedPaidIndex = 0;

    for (int i = 0; i < blocksCount; i++) {
      final blockId = "exp_${expense.id}_$i";
      final assignedCol = positions[blockId];

      if (assignedCol != null) {
        if (isFullMonth || isColumnIncluded(assignedCol)) {
          if (usedPaidIndex < paidAmounts.length) {
            totalExpenses += paidAmounts[usedPaidIndex];
            usedPaidIndex++;
          } else {
            totalExpenses += toRef(expense.amount, expense.currencyCode);
          }
        }
      }
    }
  }

  final extraExpenseTxs = await isar.financialTransactions
      .filter()
      .typeEqualTo(TransactionType.expense)
      .isRecurringEqualTo(false)
      .dateBetween(periodStart, periodEnd)
      .findAll();

  totalExpenses +=
      extraExpenseTxs.fold(0.0, (s, t) => s + t.referenceAmountWithRate(rateValue));

  DateTime generationDate =
      isNextMonth ? DateTime(now.year, now.month + 1, 1) : now;
  DateTime startOfMonth =
      DateTime(generationDate.year, generationDate.month, 1);
  DateTime endOfMonth =
      DateTime(generationDate.year, generationDate.month + 1, 0, 23, 59, 59);

  for (var debt in allDebts) {
    DateTime? date = debt.nextPaymentDate;

    int remainingInstallments = 999;
    if (debt.installmentAmount > 0) {
      remainingInstallments =
          (debt.remainingAmount / debt.installmentAmount).ceil();
    }

    if (date != null && !debt.isPaidOff && remainingInstallments > 0) {
      while (date!.isBefore(startOfMonth) && remainingInstallments > 0) {
        date = debtDao.calculateNextPaymentDate(
            date, debt.frequency, debt.customDays);
        remainingInstallments--;
      }

      while (
          (date!.isBefore(endOfMonth) || date.isAtSameMomentAs(endOfMonth)) &&
              remainingInstallments > 0) {
        final blockId = "debt_${debt.id}_${date.day}";
        final assignedCol = positions[blockId];

        if (assignedCol != null) {
          if (isFullMonth || isColumnIncluded(assignedCol)) {
            totalDebts += debt.installmentAmount;
          }
        }

        remainingInstallments--;
        if (remainingInstallments <= 0) break;

        date = debtDao.calculateNextPaymentDate(
            date, debt.frequency, debt.customDays);
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

// =============================================
//  NUEVOS PROVIDERS
// =============================================

// Salud presupuestaria
final budgetHealthProvider =
    Provider<AsyncValue<({double score, String label, Color color})>>((ref) {
  final summaryAsync = ref.watch(homeSummaryDataProvider);

  return summaryAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
    data: (data) {
      final score =
          data.income > 0 ? (data.available / data.income).clamp(0.0, 1.0) : 0.0;

      final String label;
      final Color color;

      if (score >= 0.5) {
        label = 'Buena';
        color = const Color(0xFF05D5AA);
      } else if (score >= 0.25) {
        label = 'Precaucion';
        color = const Color(0xFFFFD600);
      } else {
        label = 'Critica';
        color = const Color(0xFFFF6B6B);
      }

      return AsyncValue.data((score: score, label: label, color: color));
    },
  );
});

// Ultimas transacciones
final recentTransactionsProvider =
    StreamProvider<List<FinancialTransaction>>((ref) async* {
  final isar = await ref.watch(isarServiceProvider).db;

  yield* isar.financialTransactions
      .where()
      .sortByDateDesc()
      .limit(7)
      .watch(fireImmediately: true);
});

// Ahorros para el Home
final homeSavingsProvider = StreamProvider<List<Saving>>((ref) {
  final dao = ref.watch(savingsDaoProvider);
  return dao.watchAllSavings();
});

// Proximos pagos (gastos fijos + deudas)
final upcomingPaymentsProvider =
    FutureProvider<List<UpcomingPayment>>((ref) async {
  final now = ref.watch(nowProvider);
  final expenseDao = ref.watch(expenseDaoProvider);
  final debtDao = ref.watch(debtDaoProvider);
  final isar = await expenseDao.isarService.db;

  final List<UpcomingPayment> payments = [];

  // 1. Gastos fijos: calcular proxima fecha de pago
  final fixedExpenses =
      await isar.expenses.filter().isRecurringEqualTo(true).findAll();

  for (var expense in fixedExpenses) {
    // Obtener la siguiente fecha basada en frecuencia
    final range = getCycleDateRange(now, expense.frequency);
    final nextDate = range.end.isAfter(now) ? range.end : range.end;

    if (nextDate.isAfter(now) ||
        nextDate.isAtSameMomentAs(now)) {
      payments.add(UpcomingPayment(
        title: expense.title,
        amount: expense.amount,
        dueDate: nextDate,
        isDebt: false,
        color: const Color(0xFFFF6B6B),
        currencyCode: expense.currencyCode,
      ));
    }
  }

  // 2. Deudas activas con nextPaymentDate
  final debts = await isar.debts
      .filter()
      .isPaidOffEqualTo(false)
      .findAll();

  for (var debt in debts) {
    if (debt.nextPaymentDate != null &&
        (debt.nextPaymentDate!.isAfter(now) ||
            debt.nextPaymentDate!.isAtSameMomentAs(now))) {
      payments.add(UpcomingPayment(
        title: debt.title,
        amount: debt.installmentAmount,
        dueDate: debt.nextPaymentDate!,
        isDebt: true,
        color: const Color(0xFFFF9F43),
        currencyCode: debt.currencyCode,
      ));
    }
  }

  // Ordenar por fecha y limitar a 5
  payments.sort((a, b) => a.dueDate.compareTo(b.dueDate));
  return payments.take(5).toList();
});

// Datos del periodo anterior (para comparacion)
final previousPeriodSummaryProvider = FutureProvider<
    ({double income, double expenses, double debts, double available})?>((ref) async {
  final filter = ref.watch(summaryFilterProvider);
  final now = ref.watch(nowProvider);
  final expenseDao = ref.watch(expenseDaoProvider);
  final isar = await expenseDao.isarService.db;

  final exchangeRateService = ref.watch(exchangeRateServiceProvider);
  final currentRate = await exchangeRateService.getCurrentRate();
  final rateValue = currentRate?.rate;

  DateTime periodStart, periodEnd;

  switch (filter) {
    case SummaryFilter.currentPeriod:
    case SummaryFilter.nextPeriod:
      // Periodo anterior = quincena/semana anterior
      final ranges = await ref.watch(dynamicPeriodRangesProvider.future);
      int currentCol = 0;
      for (int i = 0; i < ranges.length; i++) {
        if (!now.isBefore(ranges[i].start) && !now.isAfter(ranges[i].end)) {
          currentCol = i;
          break;
        }
      }
      if (currentCol > 0) {
        periodStart = ranges[currentCol - 1].start;
        periodEnd = ranges[currentCol - 1].end;
      } else {
        // Primer periodo del mes: tomar ultimo del mes anterior
        final prevMonth = DateTime(now.year, now.month - 1, 1);
        periodStart = DateTime(prevMonth.year, prevMonth.month, 16);
        periodEnd = DateTime(prevMonth.year, prevMonth.month + 1, 0, 23, 59, 59);
      }
      break;
    case SummaryFilter.currentMonth:
      // Mes anterior
      final prevMonth = DateTime(now.year, now.month - 1, 1);
      periodStart = prevMonth;
      periodEnd = DateTime(prevMonth.year, prevMonth.month + 1, 0, 23, 59, 59);
      break;
    case SummaryFilter.nextMonth:
      // Mes actual (comparar con el actual)
      periodStart = DateTime(now.year, now.month, 1);
      periodEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      break;
  }

  // Ingresos del periodo anterior
  final incomeTxs = await isar.financialTransactions
      .filter()
      .typeEqualTo(TransactionType.income)
      .dateBetween(periodStart, periodEnd)
      .findAll();

  final income = incomeTxs.fold(
      0.0, (s, t) => s + t.referenceAmountWithRate(rateValue));

  // Gastos y deudas del periodo anterior — una sola query, separados en el loop
  final expenseTxs = await isar.financialTransactions
      .filter()
      .typeEqualTo(TransactionType.expense)
      .dateBetween(periodStart, periodEnd)
      .findAll();

  double expenses = 0;
  double debts = 0;
  for (var tx in expenseTxs) {
    await tx.relatedDebt.load();
    if (tx.relatedDebt.value != null) {
      debts += tx.referenceAmountWithRate(rateValue);
    } else {
      expenses += tx.referenceAmountWithRate(rateValue);
    }
  }

  final available = (income - expenses - debts).clamp(0.0, double.infinity);

  return (income: income, expenses: expenses, debts: debts, available: available);
});
