import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:finapp/logic/providers/database_providers.dart';
import 'widgets/savings_list.dart';
import 'modals/add_saving_modal.dart';

// Provider para el total ahorrado (Suma de currentAmount de todos los ahorros)
final totalSavedProvider = StreamProvider<double>((ref) async* {
  final dao = ref.watch(savingsDaoProvider);
  yield* dao.watchAllSavings().map((savings) {
    return savings.fold(0.0, (sum, s) => sum + s.currentAmount);
  });
});

// Provider para el progreso mensual
final monthlySavingsProgressProvider = StreamProvider<({double expected, double executed, int totalPlans, int executedPlans})>((ref) {
  return ref.watch(savingsDaoProvider).watchMonthlyProgress();
});

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalSavedAsync = ref.watch(totalSavedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Ahorros"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ENCABEZADO RESUMEN
          _buildSummaryHeader(context, totalSavedAsync),
          
          const Gap(10),

          // LISTA DE AHORROS
          const Expanded(
            child: SavingsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (context) => const AddSavingModal(),
          );
        },
        label: const Text("Crear Ahorro"),
        icon: const Icon(FontAwesomeIcons.piggyBank),
        backgroundColor: Colors.pinkAccent,
      ),
    );
  }

  Widget _buildSummaryHeader(BuildContext context, AsyncValue<double> totalAsync) {
    return Consumer(builder: (context, ref, _) {
      final progressAsync = ref.watch(monthlySavingsProgressProvider);
      
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pinkAccent.shade200, Colors.pink.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withAlpha(100),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          const Icon(FontAwesomeIcons.vault, color: Colors.white, size: 32),
          const Gap(10),
          const Text(
            "Total Ahorrado",
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const Gap(5),
          totalAsync.when(
            data: (total) => Text(
              "\$${total.toStringAsFixed(2)}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
            loading: () => const CircularProgressIndicator(color: Colors.white),
            error: (_, __) => const Text("Error", style: TextStyle(color: Colors.white)),
          ),
          
          const Gap(20),
          const Divider(color: Colors.white24),
          const Gap(10),

          // BARRA DE PROGRESO MENSUAL
          progressAsync.when(
            data: (data) {
              final progress = data.expected > 0 ? (data.executed / data.expected) : 0.0;
              final isOverAchieved = progress > 1.0;
              final displayProgress = progress.clamp(0.0, 1.0);
              // Si se pasó de la meta, calculamos cuánto extra es para la "capa extra" (max 20% visual extra)
              final extraProgress = isOverAchieved ? (progress - 1.0).clamp(0.0, 1.0) : 0.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Progreso Mensual", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text("${data.executedPlans}/${data.totalPlans} Cuotas", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const Gap(8),
                  Stack(
                    children: [
                      // Fondo
                      Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      // Barra Base (Hasta 100%)
                      FractionallySizedBox(
                        widthFactor: displayProgress,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      // Barra Extra (Sobre-cumplimiento) - Color Dorado/Amarillo
                      if (isOverAchieved)
                        FractionallySizedBox(
                          widthFactor: displayProgress, // Ocupa todo el ancho base
                          child: Align(
                            alignment: Alignment.centerRight, // Se alinea al final
                            child: Container(
                              width: 10, // Un indicador visual al final
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.amberAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Gap(5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("\$${data.executed.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text("Meta: \$${data.expected.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    ],
                  )
                ],
              );
            },
            loading: () => const SizedBox(height: 20),
            error: (_, __) => const SizedBox(),
          )
        ],
      ),
    );
    });
  }
}