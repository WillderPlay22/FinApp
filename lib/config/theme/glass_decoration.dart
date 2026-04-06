import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';

class GlassDecoration {
  GlassDecoration._();

  /// Decoracion principal para cards glass.
  ///
  /// Usa gradient exclusivamente — no se puede combinar color + gradient
  /// en BoxDecoration (AssertionError de Flutter).
  ///
  /// El gradient simula luz entrando desde top-left:
  ///   - Stop 0.0: highlight + base mezclados (esquina brillante)
  ///   - Stop 0.5: transicion suave
  ///   - Stop 1.0: base puro (esquina oscura)
  static BoxDecoration card(
    AppColors colors, {
    Color? accent,
    double radius = 16,
  }) {
    // Color base: si hay acento, se mezcla sutilmente para un tinte de color
    final Color base = accent != null
        ? Color.alphaBlend(
            accent.withValues(alpha: 0.15),
            colors.glassBackground,
          )
        : colors.glassBackground;

    // El highlight es el color base con capa blanca adicional — simula luz
    final Color highlight = Color.alphaBlend(
      colors.glassHighlight,
      base,
    );

    // Un mid-stop para suavizar la transicion
    final Color mid = Color.lerp(highlight, base, 0.55)!;

    // Borde: si hay acento, mezcla el acento para borde con tinte de color
    final Color borderColor = accent != null
        ? Color.alphaBlend(
            accent.withValues(alpha: 0.45),
            colors.glassBorder,
          )
        : colors.glassBorder;

    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [highlight, mid, base],
        stops: const [0.0, 0.45, 1.0],
      ),
      border: Border.all(
        color: colors.glassHighlight,
        width: 1.2,
      ),
      boxShadow: [
        // Sombra de acento (glow sutil del color)
        if (accent != null)
          BoxShadow(
            color: accent.withValues(alpha: 0.22),
            blurRadius: 32,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        // Sombra base de elevacion
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.28),
          blurRadius: 24,
          spreadRadius: -6,
          offset: const Offset(0, 10),
        ),
        // Sombra interna sutilísima (borde inferior oscuro)
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 6,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Decoracion para pills/chips (filtros, tags).
  ///
  /// Usa gradient en lugar de color para evitar el AssertionError
  /// y para mantener el efecto glass consistente.
  static BoxDecoration pill(
    AppColors colors, {
    Color? accent,
    double radius = 100,
  }) {
    final Color base = accent != null
        ? Color.alphaBlend(
            accent.withValues(alpha: 0.18),
            colors.glassBackground,
          )
        : colors.glassBackground;

    final Color highlight = Color.alphaBlend(
      colors.glassHighlight.withValues(alpha: 0.6),
      base,
    );

    final Color borderColor = accent != null
        ? accent.withValues(alpha: 0.50)
        : colors.glassBorder;

    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [highlight, base],
        stops: const [0.0, 1.0],
      ),
      border: Border.all(color: borderColor, width: 1.0),
      boxShadow: [
        if (accent != null)
          BoxShadow(
            color: accent.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: -2,
            offset: const Offset(0, 3),
          ),
      ],
    );
  }

  /// Blur estandar para BackdropFilter de cards principales.
  static ImageFilter blur(AppColors colors) {
    return ImageFilter.blur(
      sigmaX: colors.glassBlurSigma,
      sigmaY: colors.glassBlurSigma,
      tileMode: TileMode.clamp,
    );
  }

  /// Blur reducido para elementos pequeños como pills y banners.
  static ImageFilter blurSmall(AppColors colors) {
    final sigma = (colors.glassBlurSigma * 0.55).clamp(8.0, 14.0);
    return ImageFilter.blur(
      sigmaX: sigma,
      sigmaY: sigma,
      tileMode: TileMode.clamp,
    );
  }
}
