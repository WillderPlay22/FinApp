import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
// 1. Importamos las pantallas de los módulos
import '../income/income_screen.dart';
import '../expenses/expenses_screen.dart'; // <--- NUEVA IMPORTACIÓN

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Gap(20),
              
              // 1. HEADER: Saldo Disponible
              _BalanceHeader(colors: colors),
              
              const Gap(20),

              // 2. BOTÓN ESTRELLA: Simulador "¿Puedo comprarlo?"
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Abrir simulador
                    debugPrint("Abrir simulador"); 
                  },
                  icon: const Icon(FontAwesomeIcons.robot, color: Colors.white),
                  label: const Text("¿Puedo comprarlo?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    minimumSize: const Size(double.infinity, 50),
                    elevation: 4,
                  ),
                ),
              ),

              const Gap(20),

              // 3. GRID DE MENÚ (Ingresos, Gastos, Análisis, Metas)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 1.3,
                children: [
                  // --- BOTÓN INGRESOS ---
                  _MenuCard(
                    title: "Ingresos", 
                    icon: FontAwesomeIcons.arrowTrendUp, 
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => const IncomeScreen())
                      );
                    },
                  ),
                  
                  // --- BOTÓN GASTOS (AHORA CONECTADO) ---
                  _MenuCard(
                    title: "Gastos", 
                    icon: FontAwesomeIcons.arrowTrendDown, 
                    color: Colors.red,
                    onTap: () {
                      // NAVEGACIÓN A LA PANTALLA DE GASTOS
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => const ExpensesScreen())
                      );
                    },
                  ),

                  // --- OTROS BOTONES (Aún sin conectar) ---
                  _MenuCard(
                    title: "Análisis", 
                    icon: FontAwesomeIcons.chartPie, 
                    color: Colors.blue,
                    onTap: () {},
                  ),
                  _MenuCard(
                    title: "Metas", 
                    icon: FontAwesomeIcons.bullseye, 
                    color: Colors.orange,
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      // 4. FAB: Registro Rápido
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text("Gasto Rápido"),
      ),
    );
  }
}

// WIDGETS INTERNOS

class _BalanceHeader extends StatelessWidget {
  final ColorScheme colors;
  const _BalanceHeader({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Saldo Disponible", style: TextStyle(color: colors.outline)),
        const Gap(5),
        Text(
          "\$ 0.00",
          style: TextStyle(
            fontSize: 40, 
            fontWeight: FontWeight.w900,
            color: colors.primary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: colors.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "Quincena 1 - Enero",
            style: TextStyle(color: colors.onSecondaryContainer, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title, 
    required this.icon, 
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      // Usamos withValues para tu versión reciente de Flutter
      color: color.withValues(alpha: 0.1), 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const Gap(10),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}