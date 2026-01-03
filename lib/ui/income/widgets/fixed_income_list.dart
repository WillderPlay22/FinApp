import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../data/models/recurring_movement.dart';
import '../../../data/models/enums.dart';
import '../../../logic/providers/database_providers.dart';
// Importamos el nuevo modal
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
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              elevation: 0,
              // Usamos el color Surface Container para un look moderno
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: Icon(FontAwesomeIcons.rotate, color: Colors.white, size: 18),
                ),
                title: Text(movement.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_getFrequencyText(movement)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                onTap: () {
                  // ABRIR EL MODAL DE DETALLES
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true, // Para que se ajuste al contenido
                    useSafeArea: true,
                    builder: (context) => RecurringDetailModal(movement: movement),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  String _getFrequencyText(RecurringMovement movement) {
    switch (movement.frequency) {
      case Frequency.biweekly:
        return "Quincenal";
      case Frequency.monthly:
        return "Mensual";
      case Frequency.weekly:
        return "Semanal";
      case Frequency.daily:
        return "Diario";
      default:
        return "Fijo";
    }
  }
}