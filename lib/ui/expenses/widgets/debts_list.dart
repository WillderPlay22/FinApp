import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../data/models/debt.dart';
import '../../../logic/providers/database_providers.dart';
import '../modals/add_debt_modal.dart'; // For DebtFrequencyExtension
import '../modals/debt_detail_modal.dart';

class DebtsList extends ConsumerWidget {
  const DebtsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final debtsAsync = ref.watch(allDebtsProvider);

    return debtsAsync.when(
      data: (debts) {
        if (debts.isEmpty) {
          return _buildEmptyState(colors);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: debts.length,
          itemBuilder: (context, index) {
            final debt = debts[index];
            return _DebtCard(debt: debt);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err")),
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FontAwesomeIcons.fileInvoiceDollar, size: 50, color: colors.outlineVariant),
          const Gap(10),
          const Text("No tienes deudas registradas."),
        ],
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  final Debt debt;

  const _DebtCard({required this.debt});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 2);

    // Use a consistent color for debt cards, e.g., purple
    final cardColor = Colors.purple.shade700;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (context) => DebtDetailModal(debtId: debt.id),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: cardColor.withAlpha((255 * 0.4).round()),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Stack(
          children: [
            // Parte coloreada a la izquierda
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 85, // Ancho para cubrir el ícono y un poco más
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
            // Contenido sobrepuesto
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // ICONO DE DEUDA
                  Container(
                    width: 55, height: 55,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((255 * 0.2).round()),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      FontAwesomeIcons.fileInvoiceDollar, // Debt icon
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const Gap(16),
                  // DATOS DE LA DEUDA
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 5.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(debt.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colors.onSurface)),
                          const Gap(4),
                          Text("Cuotas: ${debt.installmentCount} de ${currencyFormat.format(debt.installmentAmount)}", style: TextStyle(fontSize: 12, color: colors.outline)),
                          Text("Frecuencia: ${debt.frequency.name}", style: TextStyle(fontSize: 12, color: colors.outline)), // Use the extension
                          if (debt.nextPaymentDate != null && !debt.isPaidOff)
                            Text("Próximo pago: ${DateFormat('dd MMM yyyy', 'es').format(debt.nextPaymentDate!)}", style: TextStyle(fontSize: 12, color: colors.primary)),
                          if (debt.dueDate != null && !debt.isPaidOff)
                            Text("Fecha estimada de fin: ${DateFormat('dd MMM yyyy', 'es').format(debt.dueDate!)}", style: TextStyle(fontSize: 12, color: colors.outline)),
                        ],
                      ),
                    ),
                  ),
                  // MONTO RESTANTE
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Restante", style: TextStyle(fontSize: 10, color: colors.outline)),
                      Text(currencyFormat.format(debt.remainingAmount), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: colors.primary)),
                      Icon(Icons.arrow_forward_ios, size: 12, color: colors.outline)
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}