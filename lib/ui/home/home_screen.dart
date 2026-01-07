import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../logic/providers/database_providers.dart';

// Creamos providers específicos para que la UI sea más limpia y reactiva.
final projectedExpensesProvider = StreamProvider<double>((ref) {
  return ref.watch(expenseDaoProvider).watchTotalProjectedThisMonth();
});

final projectedIncomeProvider = StreamProvider<double>((ref) {
  return ref.watch(recurringDaoProvider).watchProjectedMonthlyIncome();
});

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text("FinApp", style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary)),
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Gap(20),
              Text("Balance Mensual Proyectado", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300)),
              const Gap(20),
              _AnalysisCircle(),
              Gap(40),
              _HomeSummaryCards(),
              Gap(20),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalysisCircle extends ConsumerWidget {
  const _AnalysisCircle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeAsync = ref.watch(projectedIncomeProvider);
    final expensesAsync = ref.watch(projectedExpensesProvider);
    final colors = Theme.of(context).colorScheme;

    // Manejo de estados de carga y error
    if (incomeAsync.isLoading || expensesAsync.isLoading) {
      return const SizedBox(height: 250, width: 250, child: Center(child: CircularProgressIndicator()));
    }
    if (incomeAsync.hasError || expensesAsync.hasError) {
      return const Text("Error al calcular el resumen");
    }

    final projectedIncome = incomeAsync.value ?? 0.0;
    final projectedExpenses = expensesAsync.value ?? 0.0;
    final remaining = projectedIncome - projectedExpenses;
    // El ratio de gasto sobre el ingreso para pintar el círculo
    final expenseRatio = (projectedIncome > 0) ? (projectedExpenses / projectedIncome) : 0.0;

    final currencyFormat = NumberFormat.currency(locale: 'es_VE', symbol: '\$', decimalDigits: 0);

    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // El pintor del círculo
          SizedBox.expand(
            child: CustomPaint(
              painter: _CirclePainter(
                backgroundColor: Colors.green.shade100, // Fondo verde claro
                progressColor: Colors.red,
                progress: expenseRatio,
              ),
            ),
          ),
          // El texto en el centro
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Restante",
                style: TextStyle(fontSize: 18, color: colors.outline, fontWeight: FontWeight.w500),
              ),
              const Gap(4),
              Text(
                currencyFormat.format(remaining),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: remaining >= 0 ? const Color(0xFF2E7D32) : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _HomeSummaryCards extends ConsumerWidget {
  const _HomeSummaryCards();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeAsync = ref.watch(projectedIncomeProvider);
    final expensesAsync = ref.watch(projectedExpensesProvider);
    final currencyFormat = NumberFormat.currency(locale: 'es_VE', symbol: '\$', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              title: "Ingreso Proyectado",
              amount: incomeAsync.value ?? 0.0,
              color: Colors.green,
              icon: Icons.arrow_upward,
              isLoading: incomeAsync.isLoading,
              formatter: currencyFormat,
            ),
          ),
          const Gap(15),
          Expanded(
            child: _SummaryCard(
              title: "Gasto Proyectado",
              amount: expensesAsync.value ?? 0.0,
              color: Colors.red,
              icon: Icons.arrow_downward,
              isLoading: expensesAsync.isLoading,
              formatter: currencyFormat,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;
  final bool isLoading;
  final NumberFormat formatter;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    required this.isLoading,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const Gap(8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: colors.outline, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Gap(8),
          if (isLoading)
            const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)))
          else
            SizedBox(
              height: 28,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatter.format(amount),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colors.onSurface),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final Color backgroundColor;
  final Color progressColor;
  final double progress;

  _CirclePainter({required this.backgroundColor, required this.progressColor, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    const strokeWidth = 18.0;

    // Círculo de fondo
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, backgroundPaint);

    // Arco de progreso (gastos)
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -pi / 2; // Empezar desde arriba
    final sweepAngle = 2 * pi * progress.clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}