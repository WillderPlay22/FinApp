import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import '../../../data/models/recurring_movement.dart';
import '../../../data/models/enums.dart';
import '../../../logic/providers/database_providers.dart';
import '../../../data/daos/recurring_dao.dart';
import '../modals/recurring_detail_modal.dart';

class FixedIncomeList extends ConsumerWidget {
  const FixedIncomeList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringDao = ref.watch(recurringDaoProvider);

    return StreamBuilder<List<RecurringMovement>>(
      stream: recurringDao.watchRecurringIncomes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final movements = snapshot.data ?? [];

        if (movements.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FontAwesomeIcons.fileSignature, size: 40, color: Colors.grey),
                SizedBox(height: 10),
                Text("No tienes ingresos fijos configurados"),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: movements.length,
          padding: const EdgeInsets.only(bottom: 80),
          itemBuilder: (context, index) {
            final movement = movements[index];
            return _RecurringIncomeCard(movement: movement);
          },
        );
      },
    );
  }
}

class _RecurringIncomeCard extends ConsumerWidget {
  final RecurringMovement movement;

  const _RecurringIncomeCard({required this.movement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringDao = ref.watch(recurringDaoProvider);
    final colors = Theme.of(context).colorScheme;

    // ✅ LLAMADA DIRECTA SIN PARÁMETROS EXTRA
    return StreamBuilder<IncomeCycleStatus>(
      stream: recurringDao.watchIncomeCycleStatus(movement),
      builder: (context, snapshot) {
        final status = snapshot.data ?? IncomeCycleStatus(totalCollected: 0, paymentCount: 0, isFullyPaid: false);
        
        // Calcular monto a mostrar (Proyectado vs Real)
        double projectedAmount = 0;
        if (movement.paymentAmounts != null && movement.paymentAmounts!.isNotEmpty) {
          projectedAmount = movement.paymentAmounts!.fold(0, (sum, item) => sum + item);
        }
        
        final displayAmount = status.isFullyPaid ? status.totalCollected : projectedAmount;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          elevation: 0,
          color: status.isFullyPaid 
              ? Colors.green.withOpacity(0.1) 
              : colors.surfaceContainerHighest.withOpacity(0.3),
          shape: status.isFullyPaid 
              ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.green.withOpacity(0.5)))
              : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: status.isFullyPaid ? Colors.green : Colors.indigo,
              child: Icon(
                status.isFullyPaid ? Icons.check : FontAwesomeIcons.rotate, 
                color: Colors.white, 
                size: 18
              ),
            ),
            title: Text(
              movement.title, 
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: status.isFullyPaid ? TextDecoration.lineThrough : null,
                color: status.isFullyPaid ? Colors.green : null
              )
            ),
            subtitle: Row(
              children: [
                Text(_getFrequencyText(movement)),
                if (status.isFullyPaid) ...[
                  const Gap(8),
                  const Text("• COBRADO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.green)),
                ]
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "+ \$${displayAmount.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: status.isFullyPaid ? Colors.green : colors.onSurface
                  ),
                ),
              ],
            ),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true, 
                useSafeArea: true,
                builder: (context) => RecurringDetailModal(movement: movement),
              );
            },
          ),
        );
      },
    );
  }

  String _getFrequencyText(RecurringMovement movement) {
    switch (movement.frequency) {
      case Frequency.biweekly: return "Quincenal";
      case Frequency.monthly: return "Mensual";
      case Frequency.weekly: return "Semanal";
      case Frequency.daily: return "Diario";
      default: return "Fijo";
    }
  }
}