import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color_palettes.dart';
import '../../logic/providers/theme_provider.dart';

/// Clase para generar los ThemeData de la aplicación
class AppTheme {
  /// Genera el ThemeData para modo oscuro
  static ThemeData darkTheme([ColorPalette palette = ColorPalette.neon]) {
    final colors = getAppColors(palette, AppThemeMode.dark);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme personalizado para dark mode
      colorScheme: ColorScheme.dark(
        surface: colors.backgroundPrimary,
        primary: colors.primary,
        onPrimary: Colors.white,
        secondary: colors.primary,
        onSecondary: Colors.white,
        error: colors.error,
        onError: Colors.white,
        outline: colors.textSecondary,
        outlineVariant: colors.borderSubtle,
        surfaceContainerHighest: colors.surfaceCard,
      ),

      // Scaffolds y fondos
      scaffoldBackgroundColor: colors.backgroundPrimary,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: colors.backgroundPrimary,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
      ),

      // Cards
      cardTheme: CardThemeData(
        color: colors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surfaceCard,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // Tab Bar
      tabBarTheme: TabBarThemeData(
        labelColor: colors.primary,
        unselectedLabelColor: colors.textSecondary,
        indicatorColor: colors.primary,
        dividerColor: Colors.transparent,
      ),

      // Dividers
      dividerTheme: DividerThemeData(
        color: colors.borderSubtle,
        thickness: 1,
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        labelStyle: TextStyle(color: colors.textSecondary),
        hintStyle: TextStyle(color: colors.textDisabled),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.primary;
          }
          return colors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.primary.withAlpha(100);
          }
          return colors.surfaceElevated;
        }),
      ),

      // Fuente
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: colors.textPrimary,
        displayColor: colors.textPrimary,
      ),

      // Extension de colores personalizados
      extensions: [colors],
    );
  }

  /// Genera el ThemeData para modo claro
  static ThemeData lightTheme([ColorPalette palette = ColorPalette.neon]) {
    final colors = getAppColors(palette, AppThemeMode.light);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme personalizado para light mode
      colorScheme: ColorScheme.light(
        surface: colors.backgroundPrimary,
        primary: colors.primary,
        onPrimary: Colors.white,
        secondary: colors.primary,
        onSecondary: Colors.white,
        error: colors.error,
        onError: Colors.white,
        outline: colors.textSecondary,
        outlineVariant: colors.borderSubtle,
        surfaceContainerHighest: colors.surfaceCard,
      ),

      // Scaffolds y fondos
      scaffoldBackgroundColor: colors.backgroundPrimary,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: colors.backgroundPrimary,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
      ),

      // Cards
      cardTheme: CardThemeData(
        color: colors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.backgroundPrimary,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // Tab Bar
      tabBarTheme: TabBarThemeData(
        labelColor: colors.primary,
        unselectedLabelColor: colors.textSecondary,
        indicatorColor: colors.primary,
        dividerColor: Colors.transparent,
      ),

      // Dividers
      dividerTheme: DividerThemeData(
        color: colors.borderSubtle,
        thickness: 1,
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        labelStyle: TextStyle(color: colors.textSecondary),
        hintStyle: TextStyle(color: colors.textDisabled),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.primary;
          }
          return colors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.primary.withAlpha(100);
          }
          return colors.surfaceCard;
        }),
      ),

      // Fuente
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: colors.textPrimary,
        displayColor: colors.textPrimary,
      ),

      // Extension de colores personalizados
      extensions: [colors],
    );
  }

  /// Método legacy para compatibilidad (ahora usa lightTheme por defecto)
  @Deprecated('Usa AppTheme.lightTheme() o AppTheme.darkTheme() en su lugar')
  ThemeData getTheme() => lightTheme();
}
