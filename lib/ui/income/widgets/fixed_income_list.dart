import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:isar/isar.dart';
import '../../../data/local_db/isar_db.dart';
import '../../../data/models/recurring_movement.dart';
import '../../../date_utils.dart';
import '../../shared/icon_mapper.dart';
import '../../shared/currency_amount_display.dart';
import '../modals/recurring_detail_modal.dart';

class FixedIncomeList extends ConsumerWidget {
  const FixedIncomeList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    // Stream de todos los ingresos fijos (RecurringMovements)
    final incomeStream = Stream.fromFuture(IsarService().db).asyncExpand((isar) {
      return isar.recurringMovements.where().watch(fireImmediately: true);
    });

    return StreamBuilder<List<RecurringMovement>>(
      stream: incomeStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Error al cargar datos"));
        if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState(colors);

        final incomes = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: incomes.map((income) {
              return _FixedIncomeCard(income: income);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FontAwesomeIcons.moneyBillTransfer, size: 50, color: colors.outlineVariant),
          const Gap(10),
          const Text("No hay ingresos fijos registrados."),
        ],
      ),
    );
  }
}

class _FixedIncomeCard extends ConsumerWidget {
  final RecurringMovement income;

  const _FixedIncomeCard({required this.income});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    // Valores calculados/por defecto ya que RecurringMovement tiene una estructura diferente
    final int colorValue = Colors.teal.toARGB32(); // Color fijo para ingresos
    final int iconCode = FontAwesomeIcons.moneyBillWave.codePoint; // Icono fijo
    final double totalAmount = (income.paymentAmounts ?? []).fold(0.0, (sum, item) => sum + item);

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (context) => RecurringDetailModal(movement: income),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Color(colorValue).withAlpha((255 * 0.4).round()),
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
                  width: 85,
                  decoration: BoxDecoration(
                    color: Color(colorValue),
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
                  // ICONO
                  Container(
                    width: 55, height: 55,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((255 * 0.2).round()),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      getIconFromCode(iconCode),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const Gap(16),
                  // DATOS DEL INGRESO
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 5.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(income.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colors.onSurface)),
                          const Gap(4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: colors.secondaryContainer, borderRadius: BorderRadius.circular(8)),
                            child: Text(getFrequencyLabel(income.frequency), style: TextStyle(fontSize: 10, color: colors.onSecondaryContainer, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // MONTO
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Est. Mensual", style: TextStyle(fontSize: 10, color: colors.outline)),
                      CurrencyAmountDisplay(
                        amount: totalAmount,
                        currencyCode: income.currencyCode,
                        textAlign: TextAlign.end,
                        primaryStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: colors.primary),
                        secondaryStyle: TextStyle(fontSize: 11, color: colors.outline),
                      ),
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