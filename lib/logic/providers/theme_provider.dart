import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme/color_palettes.dart';

/// Enum para el modo de tema de la aplicacion (solo light/dark)
enum AppThemeMode {
  light,
  dark,
}

/// Estado completo del tema: modo (light/dark) + paleta de colores.
class ThemeState {
  final AppThemeMode mode;
  final ColorPalette palette;

  const ThemeState({
    required this.mode,
    required this.palette,
  });

  ThemeState copyWith({AppThemeMode? mode, ColorPalette? palette}) {
    return ThemeState(
      mode: mode ?? this.mode,
      palette: palette ?? this.palette,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeState &&
          runtimeType == other.runtimeType &&
          mode == other.mode &&
          palette == other.palette;

  @override
  int get hashCode => mode.hashCode ^ palette.hashCode;
}

/// Claves para guardar las preferencias en SharedPreferences
const String _themePrefKey = 'app_theme_mode';
const String _palettePrefKey = 'app_color_palette';

/// Provider para obtener la instancia de SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider debe ser sobrescrito en main.dart con ProviderScope.overrides',
  );
});

/// StateNotifier para manejar el estado del tema
class ThemeNotifier extends StateNotifier<ThemeState> {
  final SharedPreferences _prefs;

  ThemeNotifier(this._prefs) : super(_loadInitialState(_prefs));

  /// Carga el tema y la paleta guardados o devuelve valores por defecto
  static ThemeState _loadInitialState(SharedPreferences prefs) {
    // Modo de tema (default: light)
    final savedTheme = prefs.getString(_themePrefKey);
    final mode = savedTheme == 'dark' ? AppThemeMode.dark : AppThemeMode.light;

    // Paleta de colores (default: midnight)
    final savedPalette = prefs.getString(_palettePrefKey);
    final palette = ColorPalette.values.firstWhere(
      (p) => p.name == savedPalette,
      orElse: () => ColorPalette.midnight,
    );

    return ThemeState(mode: mode, palette: palette);
  }

  /// Cambia el modo de tema y guarda la preferencia
  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(mode: mode);
    await _prefs.setString(_themePrefKey, mode.name);
  }

  /// Cambia la paleta de colores y guarda la preferencia
  Future<void> setPalette(ColorPalette palette) async {
    state = state.copyWith(palette: palette);
    await _prefs.setString(_palettePrefKey, palette.name);
  }
}

/// Provider principal para el estado del tema
final themeNotifierProvider =
    StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});

/// Provider de conveniencia para obtener el ThemeMode de Flutter
final themeModeProvider = Provider<ThemeMode>((ref) {
  final themeState = ref.watch(themeNotifierProvider);
  return themeState.mode == AppThemeMode.light ? ThemeMode.light : ThemeMode.dark;
});

/// Provider de conveniencia para obtener la paleta actual
final currentPaletteProvider = Provider<ColorPalette>((ref) {
  return ref.watch(themeNotifierProvider).palette;
});
