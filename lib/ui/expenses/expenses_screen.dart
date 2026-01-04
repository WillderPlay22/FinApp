import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
// Importamos los widgets visuales
import 'widgets/expense_summary_header.dart';
import 'widgets/fixed_expenses_list.dart';
import 'widgets/expense_history_list.dart';
// Importamos el Modal de Registro (VITAL)
import 'modals/add_expense_modal.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          title: const Text("Mis Gastos"),
          centerTitle: true,
          elevation: 0,
        ),
        body: const Column(
          children: [
            // 1. HEADER RESUMEN (Rojo y Naranja)
            ExpenseSummaryHeader(),
            
            Gap(10),

            // 2. PESTAÑAS
            TabBar(
              tabs: [
                Tab(text: "Por Categoría", icon: Icon(FontAwesomeIcons.layerGroup)),
                Tab(text: "Historial", icon: Icon(FontAwesomeIcons.clockRotateLeft)),
              ],
            ),

            // 3. VISTAS
            Expanded(
              child: TabBarView(
                children: [
                  FixedExpensesList(), // Pestaña 1: Gastos Fijos
                  ExpenseHistoryList(), // Pestaña 2: Historial
                ],
              ),
            ),
          ],
        ),
        
        // 4. BOTÓN FLOTANTE: REGISTRAR GASTO
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            // ABRIR EL MODAL DE REGISTRO
            showModalBottomSheet(
              context: context,
              isScrollControlled: true, // Permite que el modal crezca con el teclado
              useSafeArea: true,
              builder: (context) => const AddExpenseModal(),
            );
          },
          label: const Text("Registrar Gasto"),
          icon: const Icon(FontAwesomeIcons.minus),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}