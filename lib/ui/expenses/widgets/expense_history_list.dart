import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../data/models/transaction.dart';
import '../../../data/models/enums.dart';
import '../../../date_utils.dart';
import '../../../logic/providers/time_provider.dart';
import '../../../logic/providers/currency_providers.dart';
import '../../shared/icon_mapper.dart';
import '../../shared/currency_amount_display.dart';
import '../../../logic/providers/database_providers.dart';

// --- PROVIDERS PARA EL FILTRADO DEL HISTORIAL ---

enum HistoryFilter { currentMonth, lastMonth, custom }

final historyFilterProvider = StateProvider<HistoryFilter>((ref) => HistoryFilter.currentMonth);

final historyDateRangeProvider = StateProvider<DateRange>((ref) {
  final now = ref.watch(nowProvider);
  return getCycleDateRange(now, Frequency.monthly);
});

final expenseTransactionsInDateRangeProvider = StreamProvider.family<List<FinancialTransaction>, DateRange>((ref, range) {
  final expenseDao = ref.watch(expenseDaoProvider);
  // Usamos el nuevo método que requiere un rango de fechas
  return expenseDao.watchExpenseTransactionsInDateRange(range);
});

class ExpenseHistoryList extends ConsumerWidget {
  const ExpenseHistoryList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final selectedFilter = ref.watch(historyFilterProvider);
    final dateRange = ref.watch(historyDateRangeProvider);
    final transactionsAsync = ref.watch(expenseTransactionsInDateRangeProvider(dateRange));

    return Column(
      children: [
        // --- BARRA DE FILTROS ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Wrap(
            spacing: 8.0,
            children: [
              ChoiceChip(
                label: const Text("Este Mes"),
                selected: selectedFilter == HistoryFilter.currentMonth,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(historyFilterProvider.notifier).state = HistoryFilter.currentMonth;
                    final now = ref.read(nowProvider);
                    ref.read(historyDateRangeProvider.notifier).state = getCycleDateRange(now, Frequency.monthly);
                  }
                },
              ),
              ChoiceChip(
                label: const Text("Mes Pasado"),
                selected: selectedFilter == HistoryFilter.lastMonth,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(historyFilterProvider.notifier).state = HistoryFilter.lastMonth;
                    final now = ref.read(nowProvider);
                    final lastMonth = DateTime(now.year, now.month - 1, now.day);
                    ref.read(historyDateRangeProvider.notifier).state = getCycleDateRange(lastMonth, Frequency.monthly);
                  }
                },
              ),
              ChoiceChip(
                label: const Text("Elegir..."),
                selected: selectedFilter == HistoryFilter.custom,
                onSelected: (selected) async {
                  final newRange = await _selectMonth(context, ref);
                  if (newRange != null) {
                    ref.read(historyFilterProvider.notifier).state = HistoryFilter.custom;
                    ref.read(historyDateRangeProvider.notifier).state = newRange;
                  }
                },
              ),
            ],
          ),
        ),
        // --- LISTA DE TRANSACCIONES ---
        Expanded(
          child: transactionsAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FontAwesomeIcons.ghost, size: 50, color: colors.outlineVariant),
                      const Gap(10),
                      const Text("No hay gastos en este período."),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: transactions.length,
                separatorBuilder: (c, i) => const Gap(12),
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  return Dismissible(
                    key: Key(tx.id.toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("¿Borrar del historial?"),
                          content: const Text("Esta acción eliminará el registro de este pago para siempre."),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Borrar", style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) {
                      ref.read(expenseDaoProvider).deleteTransaction(tx.id);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Transacción eliminada")));
                    },
                    child: _ExpenseHistoryItem(transaction: tx),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text("Error: $err")),
          ),
        ),
      ],
    );
  }

  Future<DateRange?> _selectMonth(BuildContext context, WidgetRef ref) async {
    final now = ref.read(nowProvider);
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => _MonthYearPickerDialog(
        initialDate: ref.read(historyDateRangeProvider).start,
        firstDate: DateTime(2020),
        lastDate: now,
      ),
    );

    if (picked != null) {
      return getCycleDateRange(picked, Frequency.monthly);
    }
    return null;
  }
}

class _ExpenseHistoryItem extends ConsumerWidget {
  final FinancialTransaction transaction;

  const _ExpenseHistoryItem({required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final isMultiCurrency = ref.watch(isMultiCurrencyEnabledProvider);

    // Determinar el ícono y color correctos.
    // Para deudas, usamos valores fijos. Para otros, usamos los de la transacción.
    final bool isDebtPayment = transaction.categoryName == "Deudas";
    final IconData icon = isDebtPayment ? FontAwesomeIcons.fileInvoiceDollar : getIconFromCode(transaction.categoryIconCode);
    final Color iconColor = isDebtPayment ? Colors.purple.shade700 : Color(transaction.colorValue);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Icono de la categoría
          Container(
            width: 45, height: 45,
            decoration: BoxDecoration(
              color: iconColor.withAlpha((255 * 0.2).round()),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          
          const Gap(12),

          // Textos centrales
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Nombre del pago (Nota)
                Text(
                  transaction.note,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // 2. Fecha y Categoría
                Row(
                  children: [
                    Text(
                      DateFormat('dd MMM - HH:mm', 'es').format(transaction.date),
                      style: TextStyle(fontSize: 11, color: colors.outline),
                    ),
                    // Separador
                    Text(" • ", style: TextStyle(fontSize: 11, color: colors.outline)),
                    
                    // Nombre de la Categoría
                    Expanded(
                      child: Text(
                        // ✅ CORREGIDO: Se elimina el '??' porque categoryName no es nulo
                        transaction.categoryName, 
                        style: TextStyle(
                          fontSize: 11, 
                          color: colors.primary.withAlpha((255 * 0.8).round()), 
                          fontWeight: FontWeight.w600
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Monto a la derecha (con soporte dual moneda)
          if (isMultiCurrency && transaction.currencyCode != null)
            CurrencyAmountDisplay(
              amount: transaction.amount,
              currencyCode: transaction.currencyCode,
              textAlign: TextAlign.end,
              primaryStyle: const TextStyle(fontWeight: FontWeight.w900, color: Colors.red, fontSize: 16),
              secondaryStyle: TextStyle(fontSize: 10, color: colors.outline),
              prefix: '- ',
            )
          else
            Text(
              "- \$${transaction.amount.toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.red, fontSize: 16),
            ),
        ],
      ),
    );
  }
}

/// Un diálogo simple para seleccionar solo mes y año.
class _MonthYearPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _MonthYearPickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
  }

  @override
  Widget build(BuildContext context) {
    final months = DateFormat.MMMM('es').dateSymbols.MONTHS;
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _selectedYear > widget.firstDate.year ? () => setState(() => _selectedYear--) : null,
          ),
          Text(
            _selectedYear.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _selectedYear < widget.lastDate.year ? () => setState(() => _selectedYear++) : null,
          ),
        ],
      ),
      content: SizedBox(
        width: 300,
        height: 300,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.5),
          itemCount: 12,
          itemBuilder: (context, index) {
            final month = index + 1;
            final isAfterLast = _selectedYear == widget.lastDate.year && month > widget.lastDate.month;
            final isBeforeFirst = _selectedYear == widget.firstDate.year && month < widget.firstDate.month;
            final isEnabled = !isAfterLast && !isBeforeFirst;

            return InkWell(
              onTap: isEnabled ? () => Navigator.of(context).pop(DateTime(_selectedYear, month)) : null,
              child: Center(
                child: Text(
                  months[index][0].toUpperCase() + months[index].substring(1),
                  style: TextStyle(
                    color: isEnabled ? colors.onSurface : colors.outline.withAlpha((255 * 0.5).round()),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancelar")),
      ],
    );
  }
}