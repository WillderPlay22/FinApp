import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/enums.dart';
import '../../../date_utils.dart';
import '../../../logic/providers/database_providers.dart';
import '../../../logic/providers/time_provider.dart';
import '../../../logic/providers/currency_providers.dart';
import '../../shared/icon_mapper.dart';
import '../../shared/currency_amount_display.dart';
import '../../../logic/models/category_with_expenses.dart';
import '../modals/fixed_category_detail_modal.dart';

class FixedExpensesList extends ConsumerWidget {
  const FixedExpensesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    // ✅ OBSERVADOR DE CAMBIOS EN CATEGORÍAS
    // Al "observar" este provider, cualquier cambio en una categoría (editar, borrar)
    // forzará la reconstrucción de este widget. Al reconstruirse, el StreamBuilder
    // de abajo se volverá a crear, obteniendo la lista de gastos actualizada.
    ref.watch(expenseCategoriesProvider);

    // 1. Obtenemos TODOS los gastos fijos
    return StreamBuilder<List<Expense>>(
      stream: ref.watch(expenseDaoProvider).watchFixedExpenses(),
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
        final rate = ref.watch(currentExchangeRateProvider).value?.rate;

        grouped.forEach((catId, catExpenses) {
          final category = catExpenses.first.category.value!;
          final totalAmount = catExpenses.fold(0.0, (sum, e) {
            if (rate != null && e.currencyCode == 'BS') {
              return sum + (e.amount / rate);
            }
            return sum + e.amount;
          });
          
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

class _FixedCategoryCard extends ConsumerWidget {
  final CategoryWithExpenses data;

  const _FixedCategoryCard({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final category = data.category;
    final budgetLimit = category.budgetLimit;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (context) => FixedCategoryDetailModal(categoryId: category.id),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Color(category.colorValue).withAlpha((255 * 0.4).round()),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 85,
                  decoration: BoxDecoration(
                    color: Color(category.colorValue),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 55, height: 55,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((255 * 0.2).round()),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          getIconFromCode(category.iconCode),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 5.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(category.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colors.onSurface)),
                              const Gap(4),
                              Text("${data.expenses.length} ítems", style: TextStyle(fontSize: 12, color: colors.outline)),
                            ],
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("Total", style: TextStyle(fontSize: 10, color: colors.outline)),
                          CurrencyAmountDisplay(
                            amount: data.totalAmount,
                            textAlign: TextAlign.end,
                            primaryStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: colors.primary),
                            secondaryStyle: TextStyle(fontSize: 11, color: colors.outline),
                          ),
                          Icon(Icons.arrow_forward_ios, size: 12, color: colors.outline)
                        ],
                      )
                    ],
                  ),
                  // INDICADOR DE PRESUPUESTO
                  if (budgetLimit != null && budgetLimit > 0)
                    _BudgetIndicator(
                      categoryId: category.id,
                      budgetLimit: budgetLimit,
                      categoryColor: Color(category.colorValue),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _BudgetIndicator extends ConsumerWidget {
  final int categoryId;
  final double budgetLimit;
  final Color categoryColor;

  const _BudgetIndicator({
    required this.categoryId,
    required this.budgetLimit,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final now = ref.watch(nowProvider);
    final monthRange = getCycleDateRange(now, Frequency.monthly);
    final expenseDao = ref.watch(expenseDaoProvider);

    return StreamBuilder<double>(
      stream: expenseDao.watchExecutedForCategory(categoryId, monthRange),
      builder: (context, snapshot) {
        final executed = snapshot.data ?? 0;
        final ratio = (executed / budgetLimit).clamp(0.0, 1.5);

        Color barColor;
        String statusText;
        if (ratio >= 1.0) {
          barColor = Colors.red;
          final excess = executed - budgetLimit;
          statusText = "Excedido por \$${NumberFormat('#,##0', 'es').format(excess)}";
        } else if (ratio >= 0.8) {
          barColor = Colors.orange;
          statusText = "Cerca del límite";
        } else {
          barColor = categoryColor;
          statusText = "";
        }

        return Padding(
          padding: const EdgeInsets.only(top: 10, left: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio.clamp(0.0, 1.0),
                        backgroundColor: colors.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(barColor),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const Gap(8),
                  Text(
                    "\$${NumberFormat('#,##0', 'es').format(executed)} / \$${NumberFormat('#,##0', 'es').format(budgetLimit)}",
                    style: TextStyle(fontSize: 10, color: colors.outline, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (statusText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(statusText, style: TextStyle(fontSize: 10, color: barColor, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        );
      },
    );
  }
}