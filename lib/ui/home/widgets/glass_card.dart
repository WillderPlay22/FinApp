import 'package:flutter/material.dart';

/// Tarjeta de superficie Material Design 3.
///
/// API compatible con el antiguo GlassCard — los parámetros [enableBlur]
/// y [accentColor] siguen existiendo: enableBlur ya no tiene efecto, y
/// accentColor añade un tinte sutil + borde de color sobre la superficie MD3.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accentColor;
  final double borderRadius;
  // ignore: avoid_unused_constructor_parameters
  final bool enableBlur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.accentColor,
    this.borderRadius = 16,
    this.enableBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final Color surfaceColor = accentColor != null
        ? Color.alphaBlend(
            accentColor!.withValues(alpha: 0.10),
            colorScheme.surfaceContainerLow,
          )
        : colorScheme.surfaceContainerLow;

    return Card(
      elevation: 0,
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
