import 'package:flutter/material.dart';
import 'app_colors.dart';
import '../../logic/providers/theme_provider.dart';

/// Enum con las paletas de colores disponibles en la app.
enum ColorPalette { neon, ocean, forest, sunset, midnight }

// ============================================================
//  OCEAN PALETTE
// ============================================================

const _oceanDark = AppColors(
  backgroundPrimary: Color(0xFF0D1B2A),
  surfaceCard: Color(0xFF152238),
  surfaceElevated: Color(0xFF1B2B45),
  borderSubtle: Color(0xFF2A3F5F),
  primary: Color(0xFF00BCD4),
  primaryHover: Color(0xFF26C6DA),
  textPrimary: Color(0xFFE0F7FA),
  textSecondary: Color(0xFF80CBC4),
  textDisabled: Color(0xFF4A6B7A),
  success: Color(0xFF00E676),
  error: Color(0xFFFF5252),
  warning: Color(0xFFFFD740),
  incomeColor: Color(0xFF00E676),
  expenseColor: Color(0xFFFF5252),
  debtColor: Color(0xFFFF9100),
  savingsColor: Color(0xFF00BCD4),
  savingsGradientStart: Color(0xFF00BCD4),
  savingsGradientEnd: Color(0xFF0097A7),
  glassBackground: Color(0x33FFFFFF),
  glassBorder: Color(0x40FFFFFF),
  glassHighlight: Color(0x33FFFFFF),
  glassBlurSigma: 20.0,
);

const _oceanLight = AppColors(
  backgroundPrimary: Color(0xFFFFFFFF),
  surfaceCard: Color(0xFFE0F7FA),
  surfaceElevated: Color(0xFFFFFFFF),
  borderSubtle: Color(0xFFB2DFDB),
  primary: Color(0xFF0097A7),
  primaryHover: Color(0xFF00838F),
  textPrimary: Color(0xFF0D1B2A),
  textSecondary: Color(0xFF546E7A),
  textDisabled: Color(0xFF90A4AE),
  success: Color(0xFF2E7D32),
  error: Color(0xFFD32F2F),
  warning: Color(0xFFF57F17),
  incomeColor: Color(0xFF2E7D32),
  expenseColor: Color(0xFFD32F2F),
  debtColor: Color(0xFFE65100),
  savingsColor: Color(0xFF0097A7),
  savingsGradientStart: Color(0xFF00ACC1),
  savingsGradientEnd: Color(0xFF00838F),
  glassBackground: Color(0xCCFFFFFF),
  glassBorder: Color(0xFFFFFFFF),
  glassHighlight: Color(0xE6FFFFFF),
  glassBlurSigma: 20.0,
);

// ============================================================
//  FOREST PALETTE
// ============================================================

const _forestDark = AppColors(
  backgroundPrimary: Color(0xFF0F1A0F),
  surfaceCard: Color(0xFF1A2B1A),
  surfaceElevated: Color(0xFF213321),
  borderSubtle: Color(0xFF2E4A2E),
  primary: Color(0xFF4CAF50),
  primaryHover: Color(0xFF66BB6A),
  textPrimary: Color(0xFFE8F5E9),
  textSecondary: Color(0xFFA5D6A7),
  textDisabled: Color(0xFF4E6B4E),
  success: Color(0xFF69F0AE),
  error: Color(0xFFEF5350),
  warning: Color(0xFFFFCA28),
  incomeColor: Color(0xFF69F0AE),
  expenseColor: Color(0xFFEF5350),
  debtColor: Color(0xFFFFB74D),
  savingsColor: Color(0xFF4CAF50),
  savingsGradientStart: Color(0xFF4CAF50),
  savingsGradientEnd: Color(0xFF2E7D32),
  glassBackground: Color(0x33FFFFFF),
  glassBorder: Color(0x40FFFFFF),
  glassHighlight: Color(0x33FFFFFF),
  glassBlurSigma: 20.0,
);

const _forestLight = AppColors(
  backgroundPrimary: Color(0xFFFFFDF7),
  surfaceCard: Color(0xFFF1F8E9),
  surfaceElevated: Color(0xFFFFFDF7),
  borderSubtle: Color(0xFFC8E6C9),
  primary: Color(0xFF2E7D32),
  primaryHover: Color(0xFF1B5E20),
  textPrimary: Color(0xFF1B2E1B),
  textSecondary: Color(0xFF558B2F),
  textDisabled: Color(0xFF9E9E9E),
  success: Color(0xFF1B5E20),
  error: Color(0xFFC62828),
  warning: Color(0xFFF9A825),
  incomeColor: Color(0xFF1B5E20),
  expenseColor: Color(0xFFC62828),
  debtColor: Color(0xFFE65100),
  savingsColor: Color(0xFF2E7D32),
  savingsGradientStart: Color(0xFF43A047),
  savingsGradientEnd: Color(0xFF1B5E20),
  glassBackground: Color(0xCCFFFFFF),
  glassBorder: Color(0xFFFFFFFF),
  glassHighlight: Color(0xE6FFFFFF),
  glassBlurSigma: 20.0,
);

// ============================================================
//  SUNSET PALETTE
// ============================================================

const _sunsetDark = AppColors(
  backgroundPrimary: Color(0xFF1A0F0F),
  surfaceCard: Color(0xFF2B1A1A),
  surfaceElevated: Color(0xFF332121),
  borderSubtle: Color(0xFF4A3030),
  primary: Color(0xFFFF7043),
  primaryHover: Color(0xFFFF8A65),
  textPrimary: Color(0xFFFFF3E0),
  textSecondary: Color(0xFFBCAAA4),
  textDisabled: Color(0xFF6D5656),
  success: Color(0xFF66BB6A),
  error: Color(0xFFEF5350),
  warning: Color(0xFFFFEE58),
  incomeColor: Color(0xFF66BB6A),
  expenseColor: Color(0xFFEF5350),
  debtColor: Color(0xFFFFB300),
  savingsColor: Color(0xFFFF7043),
  savingsGradientStart: Color(0xFFFF7043),
  savingsGradientEnd: Color(0xFFE64A19),
  glassBackground: Color(0x33FFFFFF),
  glassBorder: Color(0x40FFFFFF),
  glassHighlight: Color(0x33FFFFFF),
  glassBlurSigma: 20.0,
);

const _sunsetLight = AppColors(
  backgroundPrimary: Color(0xFFFFFBF5),
  surfaceCard: Color(0xFFFBE9E7),
  surfaceElevated: Color(0xFFFFFBF5),
  borderSubtle: Color(0xFFFFCCBC),
  primary: Color(0xFFE64A19),
  primaryHover: Color(0xFFD84315),
  textPrimary: Color(0xFF2E1A1A),
  textSecondary: Color(0xFF8D6E63),
  textDisabled: Color(0xFFBCAAA4),
  success: Color(0xFF2E7D32),
  error: Color(0xFFC62828),
  warning: Color(0xFFF57F17),
  incomeColor: Color(0xFF2E7D32),
  expenseColor: Color(0xFFC62828),
  debtColor: Color(0xFFFF8F00),
  savingsColor: Color(0xFFE64A19),
  savingsGradientStart: Color(0xFFFF7043),
  savingsGradientEnd: Color(0xFFD84315),
  glassBackground: Color(0xCCFFFFFF),
  glassBorder: Color(0xFFFFFFFF),
  glassHighlight: Color(0xE6FFFFFF),
  glassBlurSigma: 20.0,
);

// ============================================================
//  MIDNIGHT PALETTE
// ============================================================

const _midnightDark = AppColors(
  backgroundPrimary: Color(0xFF0A0E1A),
  surfaceCard: Color(0xFF131833),
  surfaceElevated: Color(0xFF1A2040),
  borderSubtle: Color(0xFF2A3060),
  primary: Color(0xFF3F51B5),
  primaryHover: Color(0xFF5C6BC0),
  textPrimary: Color(0xFFE8EAF6),
  textSecondary: Color(0xFF9FA8DA),
  textDisabled: Color(0xFF4A5090),
  success: Color(0xFF00E676),
  error: Color(0xFFFF5252),
  warning: Color(0xFFFFD740),
  incomeColor: Color(0xFF00E676),
  expenseColor: Color(0xFFFF5252),
  debtColor: Color(0xFFFFAB40),
  savingsColor: Color(0xFF7C4DFF),
  savingsGradientStart: Color(0xFF7C4DFF),
  savingsGradientEnd: Color(0xFF3F51B5),
  glassBackground: Color(0x33FFFFFF),
  glassBorder: Color(0x40FFFFFF),
  glassHighlight: Color(0x33FFFFFF),
  glassBlurSigma: 20.0,
);

const _midnightLight = AppColors(
  backgroundPrimary: Color(0xFFF8F9FF),
  surfaceCard: Color(0xFFE8EAF6),
  surfaceElevated: Color(0xFFF8F9FF),
  borderSubtle: Color(0xFFC5CAE9),
  primary: Color(0xFF283593),
  primaryHover: Color(0xFF1A237E),
  textPrimary: Color(0xFF1A1A2E),
  textSecondary: Color(0xFF5C6BC0),
  textDisabled: Color(0xFF9FA8DA),
  success: Color(0xFF2E7D32),
  error: Color(0xFFC62828),
  warning: Color(0xFFF57F17),
  incomeColor: Color(0xFF2E7D32),
  expenseColor: Color(0xFFC62828),
  debtColor: Color(0xFFE65100),
  savingsColor: Color(0xFF283593),
  savingsGradientStart: Color(0xFF5C6BC0),
  savingsGradientEnd: Color(0xFF1A237E),
  glassBackground: Color(0xCCFFFFFF),
  glassBorder: Color(0xFFFFFFFF),
  glassHighlight: Color(0xE6FFFFFF),
  glassBlurSigma: 20.0,
);

// ============================================================
//  HELPER FUNCTIONS
// ============================================================

/// Devuelve la instancia de AppColors segun la paleta y el modo de tema.
AppColors getAppColors(ColorPalette palette, AppThemeMode mode) {
  final isDark = mode == AppThemeMode.dark;
  switch (palette) {
    case ColorPalette.neon:
      return isDark ? AppColors.dark : AppColors.light;
    case ColorPalette.ocean:
      return isDark ? _oceanDark : _oceanLight;
    case ColorPalette.forest:
      return isDark ? _forestDark : _forestLight;
    case ColorPalette.sunset:
      return isDark ? _sunsetDark : _sunsetLight;
    case ColorPalette.midnight:
      return isDark ? _midnightDark : _midnightLight;
  }
}

/// Devuelve el nombre en espanol de la paleta.
String getPaletteName(ColorPalette palette) {
  switch (palette) {
    case ColorPalette.neon:
      return 'Neon';
    case ColorPalette.ocean:
      return 'Oceano';
    case ColorPalette.forest:
      return 'Bosque';
    case ColorPalette.sunset:
      return 'Atardecer';
    case ColorPalette.midnight:
      return 'Medianoche';
  }
}

/// Devuelve el color principal de vista previa para la paleta.
Color getPalettePreviewColor(ColorPalette palette) {
  switch (palette) {
    case ColorPalette.neon:
      return const Color(0xFF6C63FF);
    case ColorPalette.ocean:
      return const Color(0xFF00BCD4);
    case ColorPalette.forest:
      return const Color(0xFF4CAF50);
    case ColorPalette.sunset:
      return const Color(0xFFFF7043);
    case ColorPalette.midnight:
      return const Color(0xFF3F51B5);
  }
}

/// Devuelve los colores de vista previa para una paleta (primary, success, expense, income).
List<Color> getPalettePreviewColors(ColorPalette palette) {
  final colors = getAppColors(palette, AppThemeMode.dark);
  return [
    colors.primary,
    colors.success,
    colors.expenseColor,
    colors.incomeColor,
  ];
}
