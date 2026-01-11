import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:finapp/data/models/saving.dart';
import 'package:finapp/data/models/enums.dart';
import 'package:finapp/logic/providers/database_providers.dart';
import '../../shared/icon_mapper.dart';
import '../modals/saving_detail_modal.dart';

class SavingsList extends ConsumerWidget {
  const SavingsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(savingsDaoProvider);

    return StreamBuilder<List<Saving>>(
      stream: dao.watchAllSavings(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Error al cargar ahorros"));
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FontAwesomeIcons.seedling, size: 50, color: Colors.grey),
                Gap(10),
                Text("No tienes planes de ahorro activos."),
              ],
            ),
          );
        }

        final savings = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          itemCount: savings.length,
          itemBuilder: (context, index) => _SavingCard(saving: savings[index]),
        );
      },
    );
  }
}

class _SavingCard extends StatelessWidget {
  final Saving saving;

  const _SavingCard({required this.saving});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isGoal = saving.type == SavingType.goal;
    final progress = (isGoal && saving.targetAmount! > 0) 
        ? (saving.currentAmount / saving.targetAmount!).clamp(0.0, 1.0) 
        : 0.0;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) => SavingDetailModal(saving: saving),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Color(saving.colorValue).withAlpha((255 * 0.4).round()),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Stack(
          children: [
            // Tira de color a la izquierda (Estilo FixedExpenses)
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 85,
                  decoration: BoxDecoration(
                    color: Color(saving.colorValue),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
            
            // Contenido
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Icono Grande
                  Container(
                    width: 55, height: 55,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((255 * 0.2).round()),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(getIconFromCode(saving.iconCode), color: Colors.white, size: 24),
                  ),
                  const Gap(16),
                  
                  // Textos
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 5.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(saving.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colors.onSurface)),
                          const Gap(4),
                          // Subtitulo o Barra de Progreso
                          if (isGoal)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: colors.surfaceContainerHighest,
                                    color: Color(saving.colorValue),
                                    minHeight: 6,
                                  ),
                                ),
                                const Gap(2),
                                Text("${(progress * 100).toStringAsFixed(0)}% de \$${saving.targetAmount!.toStringAsFixed(0)}", style: TextStyle(fontSize: 10, color: colors.outline)),
                              ],
                            )
                          else
                            Text("Fondo Indefinido", style: TextStyle(fontSize: 12, color: colors.outline)),
                        ],
                      ),
                    ),
                  ),

                  // Monto a la derecha
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Total", style: TextStyle(fontSize: 10, color: colors.outline)),
                      Text("\$${saving.currentAmount.toStringAsFixed(0)}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: colors.primary)),
                      Icon(Icons.arrow_forward_ios, size: 12, color: colors.outline)
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}