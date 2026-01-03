import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'widgets/income_summary_header.dart';
import 'widgets/fixed_income_list.dart';
import 'widgets/income_history_list.dart';
import 'modals/add_income_modal.dart';

class IncomeScreen extends StatelessWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Usamos DefaultTabController para manejar las 2 pestañas (Fijos vs Historial)
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          title: const Text("Mis Ingresos"),
          centerTitle: true,
          elevation: 0,
        ),
        body: const Column(
          children: [
            // 1. TARJETAS DE RESUMEN (Percibido vs Proyectado)
            IncomeSummaryHeader(),
            
            Gap(10),

            // 2. BARRA DE PESTAÑAS
            TabBar(
              tabs: [
                Tab(text: "Mis Fijos", icon: Icon(FontAwesomeIcons.fileContract)),
                Tab(text: "Historial", icon: Icon(FontAwesomeIcons.clockRotateLeft)),
              ],
            ),

            // 3. CONTENIDO DE LAS PESTAÑAS
            Expanded(
              child: TabBarView(
                children: [
                  FixedIncomeList(),   // Pestaña 1
                  IncomeHistoryList(), // Pestaña 2
                ],
              ),
            ),
          ],
        ),
        
        // 4. BOTÓN FLOTANTE: REGISTRAR INGRESO
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            // Abrimos el Modal de registro
            showModalBottomSheet(
              context: context,
              isScrollControlled: true, // Para que pueda ocupar toda la pantalla si es necesario
              useSafeArea: true,
              builder: (context) => const AddIncomeModal(),
            );
          },
          label: const Text("Registrar Ingreso"),
          icon: const Icon(FontAwesomeIcons.plus),
        ),
      ),
    );
  }
}