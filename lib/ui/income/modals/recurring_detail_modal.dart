import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import '../../../data/models/recurring_movement.dart';
import '../../../data/models/enums.dart';
import '../../../logic/providers/database_providers.dart';

class RecurringDetailModal extends ConsumerWidget {
  final RecurringMovement movement;

  const RecurringDetailModal({super.key, required this.movement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. HEADER CON ICONO
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(FontAwesomeIcons.fileContract, size: 32, color: Colors.indigo),
          ),
          const Gap(16),
          
          Text(movement.title, style: textStyles.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          Text("Ingreso Recurrente", style: TextStyle(color: colors.outline)),
          
          const Gap(24),
          const Divider(),
          const Gap(16),

          // 2. DETALLES (GRID DE DÍAS Y MONTOS)
          Align(
            alignment: Alignment.centerLeft,
            child: Text("Especificaciones de Cobro:", style: textStyles.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          const Gap(12),
          
          // Generamos una lista visual de los días configurados
          ...List.generate(movement.paymentDays?.length ?? 0, (index) {
            final day = movement.paymentDays![index];
            final amount = movement.paymentAmounts![index];
            
            return Card(
              elevation: 0,
              color: colors.surfaceContainerHighest.withOpacity(0.3),
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  child: Text(_getDayLabel(day, movement.frequency), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                title: Text(_getDayDescription(day, movement.frequency)),
                trailing: Text(
                  "\$ ${amount.toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            );
          }),

          const Gap(30),

          // 3. BOTÓN BORRAR
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Confirmación simple
                showDialog(
                  context: context, 
                  builder: (ctx) => AlertDialog(
                    title: const Text("¿Eliminar este ingreso?"),
                    content: const Text("Esto dejará de proyectar este dinero en tus cuentas mensuales."),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
                      TextButton(
                        onPressed: () {
                          // Acción de borrar
                          ref.read(recurringDaoProvider).deleteRecurringMovement(movement.id);
                          Navigator.pop(ctx); // Cerrar alerta
                          Navigator.pop(context); // Cerrar modal
                        }, 
                        child: const Text("Eliminar", style: TextStyle(color: Colors.red))
                      ),
                    ],
                  )
                );
              },
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text("Eliminar Regla", style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const Gap(10),
        ],
      ),
    );
  }

  // Ayudantes para textos bonitos
  String _getDayLabel(int day, Frequency freq) {
    if (day == -1) return "Ult";
    if (freq == Frequency.weekly) {
      const days = ["L", "M", "M", "J", "V", "S", "D"];
      return days[(day - 1) % 7];
    }
    return "$day";
  }

  String _getDayDescription(int day, Frequency freq) {
    if (day == -1) return "Último día del mes";
    if (freq == Frequency.weekly) {
      const days = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"];
      return "Todos los ${days[(day - 1) % 7]}";
    }
    if (freq == Frequency.daily) return "Todos los días";
    return "Día $day de cada mes";
  }
}