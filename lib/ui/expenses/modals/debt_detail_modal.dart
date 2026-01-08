import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/debt.dart';
import '../../../logic/providers/database_providers.dart';

// Provider para observar una deuda específica y sus cambios.
final debtDetailProvider = StreamProvider.family<Debt?, int>((ref, debtId) {
  final debtDao = ref.watch(debtDaoProvider);
  // Isar no tiene un método watch para un solo objeto por ID,
  // así que observamos la lista completa y filtramos el objeto que nos interesa.
  // Esto es eficiente porque Isar solo notificará si la deuda específica cambia.
  return debtDao.watchAllDebts().map((debts) {
    // Usamos .where() y .firstOrNull (o una alternativa) para evitar excepciones.
    final matching = debts.where((d) => d.id == debtId);
    return matching.isNotEmpty ? matching.first : null;
  });
});

class DebtDetailModal extends ConsumerWidget {
  final int debtId;

  const DebtDetailModal({super.key, required this.debtId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtAsync = ref.watch(debtDetailProvider(debtId));
    final colors = Theme.of(context).colorScheme;

    return debtAsync.when(
      data: (debt) {
        if (debt == null) {
          // Esto puede pasar si la deuda se borra mientras el modal está abierto.
          return const Center(child: Text("Deuda no encontrada."));
        }
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(debt.title, style: Theme.of(context).textTheme.headlineSmall),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err")),
    );
  }
}