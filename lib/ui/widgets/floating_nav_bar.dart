import 'dart:math';
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

/// Barra de navegación flotante estilo Material Design 3 Expressive.
/// Al seleccionar un item, el indicador pasa por:
/// círculo → cookie 6 lóbulos → gira → regresa a círculo → se expande en pill.
class FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTap;

  const FloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTap,
  });

  static const _items = [
    (icon: Icons.home_rounded, label: 'Inicio'),
    (icon: Icons.calendar_month_rounded, label: 'Planificación'),
    (icon: Icons.settings_rounded, label: 'Ajustes'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.14),
              blurRadius: 28,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: List.generate(_items.length, (i) {
            final item = _items[i];
            return Expanded(
              child: _NavBarItem(
                icon: item.icon,
                label: item.label,
                isSelected: selectedIndex == i,
                onTap: () => onItemTap(i),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Item individual con animación cookie
// ──────────────────────────────────────────────────────────────

class _NavBarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _animPlaying = false;

  // ── Fases del timeline (t ∈ [0,1], duración total 1800ms) ──
  //
  // 0.00 – 0.08 : círculo aparece  (cookieOp 0→1)
  // 0.08 – 0.40 : morfa a cookie   (blobiness 0→1)
  // 0.40 – 0.78 : cookie girando   (blobiness = 1)
  // 0.30 – 0.80 : rotación         (0 → 2π)
  // 0.78 – 0.88 : regresa a círculo (blobiness 1→0)
  // 0.86 – 0.96 : círculo → cookieOp 1→0 / pillOp 0→1
  //               simultáneamente pill se expande (40×40 → 56×32)
  // 0.96 – 1.00 : pill en su forma final (idle)

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _ctrl.reset();
        if (mounted) setState(() => _animPlaying = false);
      }
    });
  }

  @override
  void didUpdateWidget(_NavBarItem old) {
    super.didUpdateWidget(old);
    if (widget.isSelected && !old.isSelected) {
      setState(() => _animPlaying = true);
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Helpers de animación ──────────────────────────────────

  double _blobiness(double t) {
    if (t < 0.08) return 0.0;
    if (t < 0.40) return Curves.easeOut.transform((t - 0.08) / 0.32);
    if (t < 0.78) return 1.0;
    if (t < 0.88) return 1.0 - Curves.easeIn.transform((t - 0.78) / 0.10);
    return 0.0;
  }

  double _rotation(double t) {
    if (t < 0.30) return 0.0;
    if (t < 0.80) return Curves.easeInOut.transform((t - 0.30) / 0.50) * 2 * pi;
    return 2 * pi;
  }

  /// Opacidad del pintor cookie/círculo.
  double _cookieOpacity(double t) {
    if (t < 0.08) return t / 0.08;         // aparece suavemente
    if (t > 0.86) return (0.96 - t) / 0.10; // se desvanece mientras el pill crece
    return 1.0;
  }

  /// Opacidad del pill de fondo (0 hasta la fase de expansión).
  double _pillOpacity(double t) {
    if (t < 0.86) return 0.0;
    return Curves.easeOut.transform((t - 0.86) / 0.14);
  }

  /// Ancho del pill: empieza como círculo (32) y se expande a 56.
  double _pillWidth(double t) {
    if (t < 0.86) return 32.0;
    return lerpDouble(32, 56, Curves.easeOut.transform((t - 0.86) / 0.14))!;
  }

  /// Alto del pill: empieza como círculo (32) y se mantiene en 32.
  double _pillHeight(double t) => 32.0;

  /// Border radius del pill: circular (16) → pill (16) — ya es pill al ser 32h.
  double _pillBR(double t) => 16.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value;

          // Valores durante animación vs. estado idle
          final double cookieOp =
              _animPlaying ? _cookieOpacity(t).clamp(0.0, 1.0) : 0.0;
          final double pillOp = _animPlaying
              ? _pillOpacity(t).clamp(0.0, 1.0)
              : (widget.isSelected ? 1.0 : 0.0);
          final double pillW =
              _animPlaying ? _pillWidth(t) : 56.0;
          final double pillH =
              _animPlaying ? _pillHeight(t) : 32.0;
          final double pillBR =
              _animPlaying ? _pillBR(t) : 16.0;
          final double blob = _animPlaying ? _blobiness(t) : 0.0;
          final double rot = _animPlaying ? _rotation(t) : 0.0;

          final Color iconColor;
          if (_animPlaying && cookieOp > 0.4) {
            iconColor = colorScheme.onPrimary;
          } else if (widget.isSelected) {
            iconColor = colorScheme.onSecondaryContainer;
          } else {
            iconColor = colorScheme.onSurfaceVariant;
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 56,
                height: 36,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pill / círculo expandiéndose (fase final + idle)
                    if (pillOp > 0)
                      Opacity(
                        opacity: pillOp,
                        child: Container(
                          width: pillW,
                          height: pillH,
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(pillBR),
                          ),
                        ),
                      ),
                    // Cookie / círculo animado
                    if (cookieOp > 0)
                      Opacity(
                        opacity: cookieOp,
                        child: CustomPaint(
                          size: const Size(40, 40),
                          painter: _CookiePainter(
                            blobiness: blob,
                            rotation: rot,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    // Icono siempre encima
                    Icon(widget.icon, size: 22, color: iconColor),
                  ],
                ),
              ),
              const SizedBox(height: 1),
              Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: widget.isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// CustomPainter: círculo → cookie de 6 lóbulos
// r(θ) = R · (1 + blobiness · amplitude · cos(6θ))
// ──────────────────────────────────────────────────────────────

class _CookiePainter extends CustomPainter {
  final double blobiness; // 0 = círculo, 1 = cookie completa
  final double rotation;  // radianes
  final Color color;

  const _CookiePainter({
    required this.blobiness,
    required this.rotation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rotation);

    final radius = size.shortestSide / 2;
    const amplitude = 0.10; // bumps suaves estilo cookie redondeada
    const steps = 80;
    final path = Path();

    for (int i = 0; i <= steps; i++) {
      final theta = (i / steps) * 2 * pi;
      final r = radius * (1 + blobiness * amplitude * cos(6 * theta));
      final x = r * cos(theta);
      final y = r * sin(theta);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CookiePainter old) =>
      old.blobiness != blobiness ||
      old.rotation != rotation ||
      old.color != color;
}
