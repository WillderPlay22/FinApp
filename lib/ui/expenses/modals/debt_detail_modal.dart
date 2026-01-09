import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../data/models/debt.dart';
import '../../../data/models/transaction.dart';
import '../../../logic/providers/database_providers.dart';
import 'add_debt_modal.dart'; // For DebtFrequencyExtension

// Provider para observar una deuda específica.
final debtDetailProvider = StreamProvider.family<Debt?, int>((ref, debtId) {
  final debtDao = ref.watch(debtDaoProvider);
  // ✅ Usamos watchDebt para observar una sola deuda, incluso si está pagada.
  // Esto evita que el modal se cierre automáticamente cuando la deuda se marca como pagada
  // y desaparece de la lista principal (que ahora filtra las pagadas).
  return debtDao.watchDebt(debtId);
});

class DebtDetailModal extends ConsumerWidget {
  final int debtId;

  const DebtDetailModal({super.key, required this.debtId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtAsync = ref.watch(debtDetailProvider(debtId));
    final transactionsAsync = ref.watch(debtTransactionsProvider(debtId));
    final colors = Theme.of(context).colorScheme;

    return debtAsync.when(
      data: (debt) {
        if (debt == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).pop();
          });
          return const Center(child: Text("Deuda no encontrada."));
        }
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              _buildHeader(context, ref, debt),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildSummarySection(context, debt, transactionsAsync),
                    const Gap(30),
                    _buildActions(context, ref, debt),
                    const Gap(30),
                    _buildHistorySection(context, transactionsAsync),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err")),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, Debt debt) {
    final colors = Theme.of(context).colorScheme;
    final cardColor = Colors.purple.shade700;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor.withAlpha((255 * 0.15).round()),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Row(
        children: [
          Icon(FontAwesomeIcons.fileInvoiceDollar, color: cardColor, size: 30),
          const Gap(15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(debt.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(debt.frequency.name, style: TextStyle(color: colors.outline, letterSpacing: 1.2)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_forever_outlined, color: colors.error),
            tooltip: "Eliminar Deuda",
            onPressed: () => _confirmDelete(context, ref, debt),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Debt debt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Eliminar deuda?"),
        content: Text("Se borrará la deuda '${debt.title}' y todo su historial de pagos.\n\nEsta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Eliminar", style: TextStyle(color: Theme.of(context).colorScheme.error))),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await ref.read(debtDaoProvider).deleteDebtAndTransactions(debt.id);
      // El modal se cerrará solo porque el provider emitirá null.
    }
  }

  Widget _buildSummarySection(BuildContext context, Debt debt, AsyncValue<List<FinancialTransaction>> transactionsAsync) {
    final colors = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.currency(locale: 'es', symbol: '\$');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: transactionsAsync.when(
        data: (transactions) {
          // ✅ CORRECCIÓN: El pago inicial ahora es una transacción, así que solo sumamos las transacciones.
          final totalPaid = transactions.fold(0.0, (sum, tx) => sum + tx.amount);
          // Use the original amount for a stable calculation of paid installments, robust against partial payments.
          final baseInstallmentAmount = debt.originalInstallmentAmount ?? debt.installmentAmount;
          final installmentsPaid = baseInstallmentAmount > 0 ? ((totalPaid - debt.initialPayment) / baseInstallmentAmount).floor() : 0;

          return Column(
            children: [
              _SummaryRow(label: "Próximo Pago:", value: debt.isPaidOff ? "¡Pagada!" : "${DateFormat('dd MMM yyyy', 'es').format(debt.nextPaymentDate!)} - ${currencyFormat.format(debt.installmentAmount)}"),
              const Divider(height: 20),
              _SummaryRow(label: "Total Pagado:", value: currencyFormat.format(totalPaid)),
              _SummaryRow(label: "Total Pendiente:", value: currencyFormat.format(debt.remainingAmount)),
              const Divider(height: 20),
              _SummaryRow(label: "Monto Total:", value: currencyFormat.format(debt.totalAmount)),
              _SummaryRow(label: "Cuotas Pagadas:", value: "$installmentsPaid de ${debt.installmentCount}"),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => const Center(child: Text("Error al cargar pagos.")),
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, Debt debt) {
    final colors = Theme.of(context).colorScheme;
    if (debt.isPaidOff) {
      return const Center(child: Text("Esta deuda ya ha sido saldada.", style: TextStyle(color: Colors.green)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => _confirmPayment(context, ref, debt),
          icon: const Icon(Icons.check_circle),
          label: const Text("Marcar Próxima Cuota como Pagada"),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
        const Gap(12),
        OutlinedButton.icon(
          onPressed: () => _showAmortizationOptions(context, ref, debt),
          icon: const Icon(Icons.add_card),
          label: const Text("Pagar Otro Monto"),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.primary,
            side: BorderSide(color: colors.primary),
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ],
    );
  }

  void _confirmPayment(BuildContext context, WidgetRef ref, Debt debt) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("Pagar Cuota de ${debt.title}"),
        content: Text("¿Confirmar pago de \$${debt.installmentAmount.toStringAsFixed(2)}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              // 1. Realizar el pago y verificar si se saldó la deuda
              final isPaidOff = await ref.read(debtDaoProvider).markInstallmentAsPaid(debt);
              
              // 2. Cerrar el diálogo de confirmación
              if (dialogContext.mounted) Navigator.pop(dialogContext);

              // 3. Si la deuda se pagó por completo, mostrar ventana de éxito
              if (isPaidOff && context.mounted) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("¡Felicidades!"),
                    content: const Text("Has pagado la totalidad de las cuotas de esta deuda."),
                    icon: const Icon(Icons.celebration, color: Colors.amber, size: 50),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Aceptar"),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text("Confirmar"),
          ),
        ],
      ),
    );
  }

  void _showAmortizationOptions(BuildContext context, WidgetRef ref, Debt debt) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Pagar Otro Monto", style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const Gap(20),
            ListTile(
              leading: const Icon(Icons.next_plan),
              title: const Text("Amortizar a próximas cuotas"),
              subtitle: const Text("El pago se aplica a las siguientes cuotas hasta cubrirse."),
              onTap: () async {
                Navigator.pop(ctx);
                final amount = await _showPayAmountDialog(context, "Amortizar a Capital");
                if (amount != null && amount > 0) {
                  await ref.read(debtDaoProvider).amortizeToPrincipal(debt, amount);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Amortización registrada.")));
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.view_list),
              title: const Text("Amortizar a todas las cuotas"),
              subtitle: const Text("El pago se divide entre todas las cuotas restantes, reduciendo su monto."),
              onTap: () async {
                Navigator.pop(ctx);
                final amount = await _showPayAmountDialog(context, "Amortizar a Cuotas");
                if (amount != null && amount > 0) {
                  await ref.read(debtDaoProvider).amortizeToInstallments(debt, amount);
                   if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Amortización registrada.")));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<double?> _showPayAmountDialog(BuildContext context, String title) {
    final amountController = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextFormField(
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: "Monto a Pagar",
            prefixText: "\$",
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              Navigator.pop(ctx, amount);
            },
            child: const Text("Confirmar Pago"),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context, AsyncValue<List<FinancialTransaction>> transactionsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Historial de Pagos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Gap(10),
        transactionsAsync.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("No hay pagos registrados para esta deuda."),
              ));
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (_, __) => const Gap(8),
              itemBuilder: (_, index) => _PaymentHistoryItem(transaction: transactions[index]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => const Center(child: Text("Error al cargar historial.")),
        ),
      ],
    );
  }
}

// Helper widgets must be defined at the top level, outside any other class.
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _PaymentHistoryItem extends StatelessWidget {
  final FinancialTransaction transaction;
  const _PaymentHistoryItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.currency(locale: 'es', symbol: '\$');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long, color: colors.secondary),
          const Gap(15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.note,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('dd MMM yyyy - HH:mm', 'es').format(transaction.date),
                  style: TextStyle(fontSize: 12, color: colors.outline),
                ),
              ],
            ),
          ),
          const Gap(10),
          Text(
            currencyFormat.format(transaction.amount),
            style: TextStyle(fontWeight: FontWeight.bold, color: colors.error, fontSize: 16),
          ),
        ],
      ),
    );
  }
}