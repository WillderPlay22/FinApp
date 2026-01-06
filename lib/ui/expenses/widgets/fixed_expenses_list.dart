import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/enums.dart'; 
import '../../../logic/providers/database_providers.dart';
import '../../../logic/models/category_with_expenses.dart'; // Importa el modelo nuevo
import '../modals/fixed_category_detail_modal.dart'; // El nuevo modal de detalles

class FixedExpensesList extends ConsumerWidget {
  const FixedExpensesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseDao = ref.watch(expenseDaoProvider);
    final colors = Theme.of(context).colorScheme;

    // 1. Obtenemos TODOS los gastos fijos
    return StreamBuilder<List<Expense>>(
      stream: expenseDao.watchFixedExpenses(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Error al cargar datos"));
        if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState(colors);

        final expenses = snapshot.data!;

        // 2. LÓGICA DE AGRUPACIÓN (Magia aquí)
        // Agrupamos la lista plana en un Mapa: {IdCategoria: ListaDeGastos}
        final Map<int, List<Expense>> grouped = {};
        
        for (var e in expenses) {
          final catId = e.category.value?.id;
          if (catId != null) {
            if (!grouped.containsKey(catId)) grouped[catId] = [];
            grouped[catId]!.add(e);
          }
        }

        // 3. Convertimos el mapa en una lista de nuestro modelo 'CategoryWithExpenses'
        final List<CategoryWithExpenses> categoriesData = [];

        // Necesitamos calcular el estado "pagado" de cada categoría
        // Esto es un poco complejo porque necesitamos el 'CycleStatus' de cada gasto.
        // Para simplificar la vista general, sumaremos los montos proyectados.
        // El estado real de pago lo veremos mejor dentro del detalle o con un cálculo asíncrono.
        
        grouped.forEach((catId, catExpenses) {
          final category = catExpenses.first.category.value!;
          final totalAmount = catExpenses.fold(0.0, (sum, e) => sum + e.amount);
          
          // Nota: Para obtener el 'totalSpent' real (pagado), necesitaríamos consultar 
          // el historial de transacciones. Por ahora en la vista resumen mostramos el total proyectado.
          // Si quieres ver la barra de progreso real aquí, habría que hacer una consulta más compleja.
          
          categoriesData.add(CategoryWithExpenses(
            category: category,
            expenses: catExpenses,
            totalAmount: totalAmount,
            totalSpent: 0, // Se calculará dentro del widget hijo si es necesario o en el detalle
          ));
        });

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: categoriesData.map((data) {
              return _FixedCategoryCard(data: data);
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
          Icon(FontAwesomeIcons.layerGroup, size: 50, color: colors.outlineVariant),
          const Gap(10),
          const Text("No hay categorías de gastos fijos."),
        ],
      ),
    );
  }
}

class _FixedCategoryCard extends StatelessWidget {
  final CategoryWithExpenses data;

  const _FixedCategoryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final category = data.category;

    return GestureDetector(
      onTap: () {
        // ABRIR EL DETALLE DE LA CATEGORÍA
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (context) => FixedCategoryDetailModal(data: data),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.outlineVariant.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            // ICONO DE CATEGORÍA GRANDE
            Container(
              width: 55, height: 55,
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

            // DATOS DE LA CATEGORÍA
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const Gap(4),
                  Row(
                    children: [
                      // Badge de Frecuencia
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getFrequencyLabel(category.frequency),
                          style: TextStyle(fontSize: 10, color: colors.onSecondaryContainer, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Gap(8),
                      // Conteo de items
                      Text("${data.expenses.length} ítems", style: TextStyle(fontSize: 12, color: colors.outline)),
                    ],
                  ),
                ],
              ),
            ),

            // TOTAL SUMADO
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text("Total", style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text(
                  "\$${data.totalAmount.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: colors.primary),
                ),
                const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey)
              ],
            )
          ],
        ),
      ),
    );
  }

  String _getFrequencyLabel(Frequency? freq) {
    switch (freq) {
      case Frequency.weekly: return 'SEMANAL';
      case Frequency.biweekly: return 'QUINCENAL';
      case Frequency.monthly: return 'MENSUAL';
      case Frequency.yearly: return 'ANUAL';
      default: return 'MENSUAL';
    }
  }
}