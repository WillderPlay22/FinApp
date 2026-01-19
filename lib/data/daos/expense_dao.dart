import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../date_utils.dart';
import '../local_db/isar_db.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../models/transaction.dart';
import '../models/enums.dart';
import '../../logic/providers/time_provider.dart';

/// Clase de estado para saber si un gasto fijo está pagado en el ciclo actual.
class CycleStatus {
  final double totalSpent;
  final int paymentCount;
  final bool isFullyPaid;

  CycleStatus({
    this.totalSpent = 0,
    this.paymentCount = 0,
    this.isFullyPaid = false,
  });
}

class ExpenseDao {
  final IsarService isarService;
  final Ref ref; // Referencia de Riverpod para acceder a otros providers

  ExpenseDao(this.isarService, this.ref);

  /// ✅ LÓGICA CLAVE: Marca un gasto fijo como pagado.
  /// Crea una transacción en el historial.
  /// Si se pasa [amountOverride], se usa ese monto en lugar del monto proyectado del gasto.
  Future<void> markFixedExpenseAsPaid(Expense expense,
      {double? amountOverride}) async {
    final isar = await isarService.db;
    final now =
        ref.read(nowProvider); // Usamos la fecha de la app (real o simulada)
    final category = expense.category.value;

    if (category == null) return; // Chequeo de seguridad

    final transaction = FinancialTransaction()
      ..amount =
          amountOverride ?? expense.amount // ✅ Usar monto override si existe
      ..date = now
      ..note = expense.title // El nombre del item es la nota de la transacción
      ..type = TransactionType.expense
      ..isRecurring = true
      ..categoryName = category.name
      ..categoryIconCode = category.iconCode
      ..colorValue = category.colorValue
      ..relatedExpense.value =
          expense; // Enlazamos la transacción al gasto fijo original

    await isar.writeTxn(() async {
      await isar.financialTransactions.put(transaction);
      await transaction.relatedExpense.save(); // Guardamos el enlace
    });
  }

  /// ✅ LÓGICA CLAVE: Observa el estado de un gasto para el ciclo actual.
  /// Emite un nuevo `CycleStatus` cada vez que los datos relevantes cambian.
  Stream<CycleStatus> watchCycleStatus(Expense expense) async* {
    final isar = await isarService.db;
    final category = expense.category.value;

    // Si no hay categoría o frecuencia, no se puede calcular el ciclo.
    if (category == null || category.frequency == null) {
      yield CycleStatus(); // Devuelve estado por defecto (no pagado)
      return;
    }

    // Creamos una consulta que observa las transacciones de este gasto específico.
    final query = isar.financialTransactions
        .filter()
        .relatedExpense((q) => q.idEqualTo(expense.id))
        .build();

    // `watch(fireImmediately: true)` emite un valor inicial y luego cada vez que la consulta cambia.
    await for (final _ in query.watch(fireImmediately: true)) {
      // Cada vez que hay un cambio, recalculamos todo.
      final now = ref.read(nowProvider);
      final cycleRange = getCycleDateRange(now, category.frequency!);

      // Buscamos las transacciones de este gasto DENTRO del ciclo de fechas actual.
      final transactionsInCycle = await isar.financialTransactions
          .filter()
          .relatedExpense((q) => q.idEqualTo(expense.id))
          .dateBetween(cycleRange.start, cycleRange.end,
              includeLower: true, includeUpper: true)
          .findAll();

      final isPaid = transactionsInCycle.isNotEmpty;
      final paymentCount = transactionsInCycle.length;
      final totalSpent =
          transactionsInCycle.fold<double>(0.0, (sum, tx) => sum + tx.amount);

      yield CycleStatus(
        totalSpent: totalSpent,
        paymentCount: paymentCount,
        isFullyPaid: isPaid,
      );
    }
  }

  // --- OTROS MÉTODOS DEL DAO ---

  // Guarda o actualiza un gasto (usado por AddExpenseModal)
  Future<void> saveExpense(
      {Id? id,
      required String title,
      required double amount,
      required DateTime date,
      required Category category,
      required bool isFixed,
      required Frequency frequency}) async {
    final isar = await isarService.db;

    if (isFixed) {
      // Lógica original para gastos fijos: solo se guarda la "plantilla" del gasto.
      final expense = Expense(
        title: title,
        amount: amount,
        date: date,
        isRecurring: true,
        frequency: frequency,
      )
        ..id = id ?? Isar.autoIncrement
        ..category.value = category;

      await isar.writeTxn(() async {
        await isar.expenses.put(expense);
        await expense.category.save();
      });
    } else {
      // ✅ Lógica corregida para gastos extras (no recurrentes).
      // Se crea/actualiza un 'Expense' y su 'FinancialTransaction' correspondiente.
      await isar.writeTxn(() async {
        // 1. Guardar el objeto Expense. Actúa como "master" para poder editarlo.
        final expense = Expense(
          title: title,
          amount: amount,
          date: date,
          isRecurring: false,
          frequency: Frequency.none, // No aplica
        )
          ..id = id ?? Isar.autoIncrement
          ..category.value = category;

        await isar.expenses.put(expense);
        await expense.category.save();

        // 2. Buscar si ya existe una transacción ligada a este gasto.
        FinancialTransaction? transaction;
        if (id != null) {
          transaction = await isar.financialTransactions
              .filter()
              .relatedExpense((q) => q.idEqualTo(id))
              .findFirst();
        }
        transaction ??= FinancialTransaction();

        // 3. Poblar/actualizar la transacción con los datos del 'Expense' y guardarla.
        transaction
          ..amount = expense.amount
          ..date = expense.date
          ..note = expense.title
          ..type = TransactionType.expense
          ..isRecurring = false
          ..categoryName = category.name
          ..categoryIconCode = category.iconCode
          ..colorValue = category.colorValue
          ..relatedExpense.value = expense; // Enlazamos

        await isar.financialTransactions.put(transaction);
        await transaction.relatedExpense.save();
      });
    }
  }

  // Actualiza un gasto (usado en el diálogo de edición simple)
  Future<void> updateExpense(Expense expense) async {
    final isar = await isarService.db;
    await isar.writeTxn(() async {
      await isar.expenses.put(expense);
    });
  }

  // Borra un gasto y sus transacciones asociadas
  Future<void> deleteExpense(Id expenseId) async {
    final isar = await isarService.db;
    await isar.writeTxn(() async {
      // Borra las transacciones del historial que pertenecen a este gasto
      await isar.financialTransactions
          .filter()
          .relatedExpense((q) => q.idEqualTo(expenseId))
          .deleteAll();
      // Borra el gasto
      await isar.expenses.filter().idEqualTo(expenseId).deleteAll();
    });
  }

  // Borra una categoría, sus gastos asociados y las transacciones de esos gastos.
  Future<void> deleteCategoryAndRelatedData(Id categoryId) async {
    final isar = await isarService.db;
    await isar.writeTxn(() async {
      // 1. Encontrar todos los gastos de esta categoría
      final expensesToDelete = await isar.expenses
          .filter()
          .category((q) => q.idEqualTo(categoryId))
          .findAll();
      final expenseIds = expensesToDelete.map((e) => e.id).toList();

      if (expenseIds.isNotEmpty) {
        // 2. Borrar todas las transacciones que apuntan a esos gastos
        await isar.financialTransactions
            .filter()
            .anyOf(expenseIds,
                (q, int id) => q.relatedExpense((r) => r.idEqualTo(id)))
            .deleteAll();

        // 3. Borrar todos los gastos de la categoría
        await isar.expenses.deleteAll(expenseIds);
      }

      // 4. Finalmente, borrar la categoría
      await isar.categorys.delete(categoryId);
    });
  }

  // Borra una transacción individual del historial
  Future<void> deleteTransaction(Id transactionId) async {
    final isar = await isarService.db;
    await isar.writeTxn(() async {
      await isar.financialTransactions
          .filter()
          .idEqualTo(transactionId)
          .deleteAll();
    });
  }

  // Observa todos los gastos fijos (para la lista principal)
  Stream<List<Expense>> watchFixedExpenses() async* {
    final isar = await isarService.db;
    yield* isar.expenses
        .filter()
        .isRecurringEqualTo(true)
        .watch(fireImmediately: true);
  }

  // Observa los gastos de una categoría específica
  Stream<List<Expense>> watchExpensesForCategory(int categoryId) async* {
    final isar = await isarService.db;
    yield* isar.expenses
        .filter()
        .category((q) => q.idEqualTo(categoryId))
        .watch(fireImmediately: true);
  }

  // ✅ Observa el historial de transacciones de gastos para un período específico.
  Stream<List<FinancialTransaction>> watchExpenseTransactionsInDateRange(
      DateRange range) async* {
    final isar = await isarService.db;
    yield* isar.financialTransactions
        .where()
        .filter()
        .typeEqualTo(TransactionType.expense)
        .dateBetween(range.start, range.end)
        .sortByDateDesc()
        .watch(fireImmediately: true);
  }

  // --- MÉTODOS PARA LOS GRÁFICOS ---

  /// ✅ Observa el resumen de gastos EJECUTADOS y los agrupa por categoría para un rango de fechas.
  /// Usado por el gráfico en la pestaña "Historial".
  Stream<Map<String, ({double total, int color})>>
      watchCategorizedSummaryInDateRange(DateRange range) async* {
    final isar = await isarService.db;
    final query = isar.financialTransactions
        .filter()
        .typeEqualTo(TransactionType.expense)
        .dateBetween(range.start, range.end)
        .build();

    await for (final transactions in query.watch(fireImmediately: true)) {
      final Map<String, ({double total, int color})> summaryMap = {};
      if (transactions.isEmpty) {
        yield summaryMap;
        continue;
      }

      for (final tx in transactions) {
        final current =
            summaryMap[tx.categoryName] ?? (total: 0.0, color: tx.colorValue);
        summaryMap[tx.categoryName] =
            (total: current.total + tx.amount, color: tx.colorValue);
      }
      yield summaryMap;
    }
  }

  /// ✅ Observa la PROYECCIÓN de gastos fijos y los agrupa por categoría.
  /// Usado como una de las fuentes para el gráfico en la pestaña "Categorías".
  Stream<Map<String, ({double total, int color})>>
      watchCategorizedFixedProjection() async* {
    final isar = await isarService.db;
    final query = isar.expenses.filter().isRecurringEqualTo(true).build();
    await for (final fixedExpenses in query.watch(fireImmediately: true)) {
      final Map<String, ({double total, int color})> projectionMap = {};
      for (final expense in fixedExpenses) {
        final category = expense.category.value;
        if (category == null) continue;
        final monthlyAmount = getMonthlyAmount(expense);
        final current = projectionMap[category.name] ??
            (total: 0.0, color: category.colorValue);
        projectionMap[category.name] =
            (total: current.total + monthlyAmount, color: category.colorValue);
      }
      yield projectionMap;
    }
  }

  /// ✅ Observa los gastos EXTRA (no recurrentes) en un rango de fechas y los agrupa por categoría.
  /// Usado como fuente para el gráfico en la pestaña "Categorías".
  Stream<Map<String, ({double total, int color})>>
      watchCategorizedExtrasInDateRange(DateRange range) async* {
    final isar = await isarService.db;
    final query = isar.financialTransactions
        .filter()
        .typeEqualTo(TransactionType.expense)
        .isRecurringEqualTo(false)
        .dateBetween(range.start, range.end)
        .build();

    await for (final transactions in query.watch(fireImmediately: true)) {
      final Map<String, ({double total, int color})> summaryMap = {};
      for (final tx in transactions) {
        final current =
            summaryMap[tx.categoryName] ?? (total: 0.0, color: tx.colorValue);
        summaryMap[tx.categoryName] =
            (total: current.total + tx.amount, color: tx.colorValue);
      }
      yield summaryMap;
    }
  }

  // --- MÉTODOS PARA EL HEADER DE RESUMEN ---

  /// Observa el total de gastos REALES ejecutados en el mes actual.
  Stream<double> watchTotalExecutedThisMonth() async* {
    final isar = await isarService.db;
    final now = ref.read(nowProvider);
    final monthRange = getCycleDateRange(now, Frequency.monthly);

    final query = isar.financialTransactions
        .filter()
        .typeEqualTo(TransactionType.expense)
        .dateBetween(monthRange.start, monthRange.end)
        .build();

    await for (final transactions in query.watch(fireImmediately: true)) {
      final total =
          transactions.fold<double>(0.0, (sum, tx) => sum + tx.amount);
      yield total;
    }
  }

  /// Observa el total de gastos PROYECTADO para el mes actual.
  Stream<double> watchTotalProjectedThisMonth() async* {
    final isar = await isarService.db;

    final query = isar.expenses.where().build();

    await for (final _ in query.watch(fireImmediately: true)) {
      double projectedTotal = 0;
      // 1. Sumar la proyección de todos los gastos fijos
      final fixedExpenses =
          await isar.expenses.filter().isRecurringEqualTo(true).findAll();
      for (final expense in fixedExpenses) {
        projectedTotal += getMonthlyAmount(expense);
      }

      // 2. Sumar los gastos extra (no recurrentes) ya ejecutados este mes
      final now = ref.read(nowProvider);
      final monthRange = getCycleDateRange(now, Frequency.monthly);
      final extraTransactions = await isar.financialTransactions
          .filter()
          .isRecurringEqualTo(false)
          .typeEqualTo(TransactionType.expense)
          .dateBetween(monthRange.start, monthRange.end)
          .findAll();
      projectedTotal +=
          extraTransactions.fold<double>(0.0, (sum, tx) => sum + tx.amount);

      yield projectedTotal;
    }
  }

  // Helper para calcular el valor mensual de un gasto fijo
  double getMonthlyAmount(Expense expense) {
    switch (expense.frequency) {
      case Frequency.daily:
        return expense.amount * 30;
      case Frequency.weekly:
        return expense.amount * 4;
      case Frequency.biweekly:
        return expense.amount * 2;
      case Frequency.monthly:
        return expense.amount;
      case Frequency.yearly:
        return expense.amount / 12;
      case Frequency.none:
        return 0;
    }
  }
}
