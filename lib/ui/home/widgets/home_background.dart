import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';

/// Fondo del HomeScreen con blobs de color difuminados sobre gradiente base.
///
/// En dark mode: gradiente profundo azul-violeta + blobs de colores primarios
/// con opacidad suficiente para que el efecto glass de las cards sea visible.
///
/// En light mode: blobs suaves sobre fondo blanco-azulado para dar profundidad.
class HomeBackground extends StatelessWidget {
  final double scrollOffset;

  const HomeBackground({super.key, this.scrollOffset = 0});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final size = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _GradientBlobsPainter(
            primary: colors.primary,
            income: colors.incomeColor,
            savings: colors.savingsColor,
            expense: colors.expenseColor,
            scrollOffset: scrollOffset,
            screenWidth: size.width,
            screenHeight: size.height,
            isDark: isDark,
          ),
        ),
      ),
    );
  }
}

class _GradientBlobsPainter extends CustomPainter {
  final Color primary;
  final Color income;
  final Color savings;
  final Color expense;
  final double scrollOffset;
  final double screenWidth;
  final double screenHeight;
  final bool isDark;

  /// Blur mas alto = blobs mas difuminados y naturales.
  /// 110 da un aspecto de neblina suave, similar a las referencias visuales.
  static const _blobBlur = MaskFilter.blur(BlurStyle.normal, 110);

  late final Paint _paintPrimary;
  late final Paint _paintIncome;
  late final Paint _paintSavings;
  late final Paint _paintExpense;
  late final Paint _paintPrimaryMid;

  _GradientBlobsPainter({
    required this.primary,
    required this.income,
    required this.savings,
    required this.expense,
    required this.scrollOffset,
    required this.screenWidth,
    required this.screenHeight,
    required this.isDark,
  }) {
    // Dark mode: blobs opacos para contrastar con fondo oscuro
    // Light mode: blobs visibles (min 0.28) para que el glass effect trasluzca algo
    final double blobOpacity = isDark ? 0.50 : 0.35;
    final double secondaryOpacity = isDark ? 0.40 : 0.28;
    final double tertiaryOpacity = isDark ? 0.32 : 0.22;

    _paintPrimary = Paint()
      ..color = primary.withValues(alpha: blobOpacity)
      ..maskFilter = _blobBlur;

    _paintIncome = Paint()
      ..color = income.withValues(alpha: secondaryOpacity)
      ..maskFilter = _blobBlur;

    _paintSavings = Paint()
      ..color = savings.withValues(alpha: blobOpacity)
      ..maskFilter = _blobBlur;

    _paintExpense = Paint()
      ..color = expense.withValues(alpha: tertiaryOpacity)
      ..maskFilter = _blobBlur;

    // Segundo blob primary en posicion diferente para profundidad
    _paintPrimaryMid = Paint()
      ..color = primary.withValues(alpha: tertiaryOpacity)
      ..maskFilter = _blobBlur;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final p = scrollOffset * 0.12; // parallax suave

    // --- Blobs estrategicamente posicionados ---
    //
    // Blob 1 (primary violeta): top-right — el mas grande y prominente
    // Ancla visual superior de la pantalla
    canvas.drawCircle(
      Offset(size.width * 0.85, -size.height * 0.05 - p),
      size.width * 0.65,
      _paintPrimary,
    );

    // Blob 2 (income verde azulado): mid-left — da profundidad en la zona media
    canvas.drawCircle(
      Offset(-size.width * 0.20, size.height * 0.30 - p * 0.8),
      size.width * 0.55,
      _paintIncome,
    );

    // Blob 3 (savings magenta): bottom-right — anclaje inferior
    canvas.drawCircle(
      Offset(size.width * 0.90, size.height * 0.62 - p * 0.6),
      size.width * 0.58,
      _paintSavings,
    );

    // Blob 4 (primary secundario): centro — neblina de profundidad
    // Este blob hace que el efecto glass se vea en toda la pantalla
    canvas.drawCircle(
      Offset(size.width * 0.45, size.height * 0.48 - p * 0.4),
      size.width * 0.70,
      _paintPrimaryMid,
    );

    // Blob 5 (expense rojizo): top-left — acento sutil en la esquina opuesta
    canvas.drawCircle(
      Offset(-size.width * 0.10, size.height * 0.08 - p * 1.1),
      size.width * 0.40,
      _paintExpense,
    );
  }

  @override
  bool shouldRepaint(_GradientBlobsPainter old) {
    return old.scrollOffset != scrollOffset ||
        old.primary != primary ||
        old.income != income ||
        old.savings != savings ||
        old.expense != expense ||
        old.isDark != isDark;
  }
}
