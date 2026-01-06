import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import '../income/income_screen.dart';
import '../expenses/expenses_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      // ✅ AppBar Limpio: Solo título, sin botón de debug
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text(
          "FinApp", 
          style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary)
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Gap(10),
              
              _BalanceHeader(colors: colors),
              const Gap(20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton.icon(
                  onPressed: () {},
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

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 1.3,
                children: [
                  _MenuCard(
                    title: "Ingresos", 
                    icon: FontAwesomeIcons.arrowTrendUp, 
                    color: Colors.green, 
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IncomeScreen()))
                  ),
                  _MenuCard(
                    title: "Gastos", 
                    icon: FontAwesomeIcons.arrowTrendDown, 
                    color: Colors.red, 
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpensesScreen()))
                  ),
                  _MenuCard(
                    title: "Análisis", 
                    icon: FontAwesomeIcons.chartPie, 
                    color: Colors.blue, 
                    onTap: () {}
                  ),
                  _MenuCard(
                    title: "Metas", 
                    icon: FontAwesomeIcons.bullseye, 
                    color: Colors.orange, 
                    onTap: () {}
                  ),
                ],
              ),
              const Gap(80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpensesScreen())),
        icon: const Icon(Icons.add),
        label: const Text("Gasto Rápido"),
      ),
    );
  }
}

class _BalanceHeader extends StatelessWidget {
  final ColorScheme colors;
  const _BalanceHeader({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Saldo Disponible", style: TextStyle(color: colors.outline)),
        const Gap(5),
        Text("\$ 0.00", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: colors.primary)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: colors.secondaryContainer, borderRadius: BorderRadius.circular(20)),
          child: Text("Quincena Actual", style: TextStyle(color: colors.onSecondaryContainer, fontSize: 12)),
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
  const _MenuCard({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
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