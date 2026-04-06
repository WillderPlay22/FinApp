import 'package:flutter/material.dart';

/// Clase que define la paleta de colores de la aplicación para ambos modos (claro/oscuro).
///
/// Uso: `AppColors.of(context).primary` para obtener el color según el tema actual.
class AppColors extends ThemeExtension<AppColors> {
  // Fondos y Superficies
  final Color backgroundPrimary;
  final Color surfaceCard;
  final Color surfaceElevated;
  final Color borderSubtle;

  // Colores de Acento (Marca)
  final Color primary;
  final Color primaryHover;

  // Tipografía
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;

  // Colores Semánticos
  final Color success;
  final Color error;
  final Color warning;

  // Colores específicos de módulos
  final Color incomeColor; // Para ingresos
  final Color expenseColor; // Para gastos
  final Color debtColor; // Para deudas
  final Color savingsColor; // Para ahorros
  final Color savingsGradientStart;
  final Color savingsGradientEnd;

  // Glassmorphism tokens
  final Color glassBackground;
  final Color glassBorder;
  final Color glassHighlight;
  final double glassBlurSigma;

  const AppColors({
    required this.backgroundPrimary,
    required this.surfaceCard,
    required this.surfaceElevated,
    required this.borderSubtle,
    required this.primary,
    required this.primaryHover,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.success,
    required this.error,
    required this.warning,
    required this.incomeColor,
    required this.expenseColor,
    required this.debtColor,
    required this.savingsColor,
    required this.savingsGradientStart,
    required this.savingsGradientEnd,
    required this.glassBackground,
    required this.glassBorder,
    required this.glassHighlight,
    required this.glassBlurSigma,
  });

  // ============ MODO OSCURO (Dark Mode) ============
  // Paleta tech/neón con fondos profundos
  static const dark = AppColors(
    // Fondos y Superficies
    backgroundPrimary: Color(0xFF121212), // Negro Mate
    surfaceCard: Color(0xFF1E1E24), // Gris Carbón (Nivel 1)
    surfaceElevated: Color(0xFF27272F), // Gris Carbón claro (Nivel 2)
    borderSubtle: Color(0xFF3A3A42), // Borde sutil para dark mode

    // Color de Acento
    primary: Color(0xFF6C63FF), // Violeta Eléctrico
    primaryHover: Color(0xFF827AFF), // Violeta más claro

    // Tipografía
    textPrimary: Color(0xFFF4F4F5), // Blanco Humo
    textSecondary: Color(0xFFA1A1AA), // Gris Medio Frío
    textDisabled: Color(0xFF52525B), // Gris Oscuro

    // Colores Semánticos (Neón)
    success: Color(0xFF05D5AA), // Verde Azulado Neón
    error: Color(0xFFFF6B6B), // Rojo Coral Neón
    warning: Color(0xFFFFD600), // Amarillo Eléctrico

    // Colores de Módulos
    incomeColor: Color(0xFF05D5AA), // Verde Azulado Neón (igual a success)
    expenseColor: Color(0xFFFF6B6B), // Rojo Coral Neón (igual a error)
    debtColor: Color(0xFFFF9F43), // Naranja Neón
    savingsColor: Color(0xFFE056FD), // Magenta Neón
    savingsGradientStart: Color(0xFFE056FD), // Magenta
    savingsGradientEnd: Color(0xFF9B59B6), // Púrpura
    glassBackground: Color(0x33FFFFFF), // white @ 20%
    glassBorder: Color(0x4DFFFFFF), // white @ 30%
    glassHighlight: Color(0x4DFFFFFF), // white @ 30%
    glassBlurSigma: 22.0,
  );

  // ============ MODO CLARO (Light Mode) ============
  // Paleta limpia con acentos intensos adaptados
  static const light = AppColors(
    // Fondos y Superficies
    backgroundPrimary: Color(0xFFFFFFFF), // Blanco Puro
    surfaceCard: Color(0xFFF4F5F7), // Gris Frío Muy Claro
    surfaceElevated: Color(0xFFFFFFFF), // Blanco para modales
    borderSubtle: Color(0xFFE5E7EB), // Gris Claro para bordes

    // Color de Acento (Adaptado para buen contraste)
    primary: Color(0xFF5A51E0), // Violeta Intenso
    primaryHover: Color(0xFF483FD6), // Violeta Profundo

    // Tipografía
    textPrimary: Color(0xFF111827), // Negro Carbón
    textSecondary: Color(0xFF6B7280), // Gris Medio
    textDisabled: Color(0xFF9CA3AF), // Gris Claro

    // Colores Semánticos (Adaptados para legibilidad)
    success: Color(0xFF059669), // Verde Esmeralda
    error: Color(0xFFDC2626), // Rojo Fuerte
    warning: Color(0xFFD97706), // Ámbar / Naranja oscuro

    // Colores de Módulos
    incomeColor: Color(0xFF059669), // Verde Esmeralda (igual a success)
    expenseColor: Color(0xFFDC2626), // Rojo Fuerte (igual a error)
    debtColor: Color(0xFFEA580C), // Naranja intenso
    savingsColor: Color(0xFFDB2777), // Rosa intenso
    savingsGradientStart: Color(0xFFEC4899), // Rosa claro
    savingsGradientEnd: Color(0xFFBE185D), // Rosa oscuro
    glassBackground: Color(0xCCFFFFFF), // white @ 80% — frosted opaco visible sobre fondo con color
    glassBorder: Color(0xFFFFFFFF), // white @ 100% — borde brillante efecto catch-light
    glassHighlight: Color(0xE6FFFFFF), // white @ 90% — highlight top-left
    glassBlurSigma: 20.0,
  );

  /// Obtiene la instancia de AppColors según el tema actual.
  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>() ?? dark;
  }

  @override
  AppColors copyWith({
    Color? backgroundPrimary,
    Color? surfaceCard,
    Color? surfaceElevated,
    Color? borderSubtle,
    Color? primary,
    Color? primaryHover,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? success,
    Color? error,
    Color? warning,
    Color? incomeColor,
    Color? expenseColor,
    Color? debtColor,
    Color? savingsColor,
    Color? savingsGradientStart,
    Color? savingsGradientEnd,
    Color? glassBackground,
    Color? glassBorder,
    Color? glassHighlight,
    double? glassBlurSigma,
  }) {
    return AppColors(
      backgroundPrimary: backgroundPrimary ?? this.backgroundPrimary,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      primary: primary ?? this.primary,
      primaryHover: primaryHover ?? this.primaryHover,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      success: success ?? this.success,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      incomeColor: incomeColor ?? this.incomeColor,
      expenseColor: expenseColor ?? this.expenseColor,
      debtColor: debtColor ?? this.debtColor,
      savingsColor: savingsColor ?? this.savingsColor,
      savingsGradientStart: savingsGradientStart ?? this.savingsGradientStart,
      savingsGradientEnd: savingsGradientEnd ?? this.savingsGradientEnd,
      glassBackground: glassBackground ?? this.glassBackground,
      glassBorder: glassBorder ?? this.glassBorder,
      glassHighlight: glassHighlight ?? this.glassHighlight,
      glassBlurSigma: glassBlurSigma ?? this.glassBlurSigma,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      backgroundPrimary:
          Color.lerp(backgroundPrimary, other.backgroundPrimary, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      incomeColor: Color.lerp(incomeColor, other.incomeColor, t)!,
      expenseColor: Color.lerp(expenseColor, other.expenseColor, t)!,
      debtColor: Color.lerp(debtColor, other.debtColor, t)!,
      savingsColor: Color.lerp(savingsColor, other.savingsColor, t)!,
      savingsGradientStart:
          Color.lerp(savingsGradientStart, other.savingsGradientStart, t)!,
      savingsGradientEnd:
          Color.lerp(savingsGradientEnd, other.savingsGradientEnd, t)!,
      glassBackground: Color.lerp(glassBackground, other.glassBackground, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassHighlight: Color.lerp(glassHighlight, other.glassHighlight, t)!,
      glassBlurSigma:
          glassBlurSigma + (other.glassBlurSigma - glassBlurSigma) * t,
    );
  }
}
