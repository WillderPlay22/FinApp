import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import '../../../data/models/category.dart';
import '../../../data/models/enums.dart'; 
import '../../../logic/providers/database_providers.dart';

class FixedExpensesList extends ConsumerWidget {
  const FixedExpensesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryDao = ref.watch(categoryDaoProvider);
    final colors = Theme.of(context).colorScheme;

    return StreamBuilder<List<Category>>(
      stream: categoryDao.watchExpenseCategories(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Error al cargar datos"));
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(colors);
        }

        final categories = snapshot.data!;

        // CAMBIO CLAVE: Usamos SingleChildScrollView + Column para poder ocultar 
        // elementos (SizedBox.shrink) sin dejar huecos de separadores extraños.
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: categories.map((category) {
              return _CategoryCard(category: category);
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
          Icon(FontAwesomeIcons.boxOpen, size: 50, color: colors.outlineVariant),
          const Gap(10),
          const Text("No tienes gastos fijos registrados."),
          const Gap(5),
          const Text("Registra un gasto 'Fijo' para verlo aquí.", style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  final Category category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final categoryDao = ref.watch(categoryDaoProvider);

    return FutureBuilder<double>(
      future: categoryDao.getCategoryFixedTotal(category.id),
      initialData: 0.0, // Inicialmente asumimos 0 para que no salte
      builder: (context, snapshot) {
        final totalAmount = snapshot.data ?? 0.0;
        
        // --- FILTRO MÁGICO ---
        // Si el total es 0, devolvemos una caja invisible (shrink).
        // Así la categoría desaparece de la lista.
        if (totalAmount <= 0) {
          return const SizedBox.shrink();
        }

        double percentage = 0.5; // Placeholder visual del %

        // Si tiene monto, mostramos la tarjeta con un margen inferior (Gap)
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            elevation: 0,
            color: colors.surfaceContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Detalle de ${category.name} próximamente"))
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // 1. ICONO
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: Color(category.colorValue).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        IconData(category.iconCode, fontFamily: 'FontAwesomeSolid', fontPackage: 'font_awesome_flutter'),
                        color: Color(category.colorValue),
                        size: 24,
                      ),
                    ),
                    
                    const Gap(16),

                    // 2. DATOS
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const Gap(8),
                              if (category.frequency != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colors.outlineVariant.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _getFrequencyText(category.frequency!),
                                    style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
                                  ),
                                ),
                            ],
                          ),
                          const Gap(8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage, 
                              backgroundColor: colors.surface,
                              color: Color(category.colorValue),
                              minHeight: 6,
                            ),
                          ),
                          const Gap(4),
                          Text(
                            "Impacto en presupuesto",
                            style: TextStyle(fontSize: 10, color: colors.outline),
                          ),
                        ],
                      ),
                    ),

                    const Gap(10),

                    // 3. MONTO
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "\$ ${totalAmount.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.w900, 
                            color: colors.onSurface
                          ),
                        ),
                        const Text("Acumulado", style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getFrequencyText(Frequency freq) {
    switch (freq) {
      case Frequency.weekly: return 'Semanal';
      case Frequency.biweekly: return 'Quincenal';
      case Frequency.monthly: return 'Mensual';
      case Frequency.yearly: return 'Anual';
      default: return '';
    }
  }
}