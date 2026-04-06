import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/color_palettes.dart';
import '../../logic/providers/theme_provider.dart';
import '../../logic/providers/currency_providers.dart';
import '../../logic/providers/decimal_separator_provider.dart';

/// Pantalla de configuracion de la aplicacion
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = AppColors.of(context);
    final themeState = ref.watch(themeNotifierProvider);
    final isDarkMode = themeState.mode == AppThemeMode.dark;
    final currentPalette = themeState.palette;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuracion'),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          // Seccion de Apariencia
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Apariencia',
              style: TextStyle(
                color: appColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Card con selector de tema
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: appColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: appColors.borderSubtle),
            ),
            child: Row(
              children: [
                // Opcion Claro
                Expanded(
                  child: _buildThemeOption(
                    context: context,
                    icon: Icons.light_mode_outlined,
                    label: 'Claro',
                    isSelected: !isDarkMode,
                    onTap: () => ref.read(themeNotifierProvider.notifier).setThemeMode(AppThemeMode.light),
                  ),
                ),
                const SizedBox(width: 12),
                // Opcion Oscuro
                Expanded(
                  child: _buildThemeOption(
                    context: context,
                    icon: Icons.dark_mode_outlined,
                    label: 'Oscuro',
                    isSelected: isDarkMode,
                    onTap: () => ref.read(themeNotifierProvider.notifier).setThemeMode(AppThemeMode.dark),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Seccion de Paleta de Colores
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Paleta de Colores',
              style: TextStyle(
                color: appColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Grid de paletas
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ColorPalette.values.map((palette) {
              final isSelected = currentPalette == palette;
              final previewColors = getPalettePreviewColors(palette);
              return GestureDetector(
                onTap: () => ref.read(themeNotifierProvider.notifier).setPalette(palette),
                child: Container(
                  width: (MediaQuery.of(context).size.width - 32 - 20) / 3,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? appColors.primary.withAlpha(25)
                        : appColors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? appColors.primary : appColors.borderSubtle,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Circulos de vista previa
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: previewColors.map((color) {
                          return Container(
                            width: 16,
                            height: 16,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: appColors.borderSubtle,
                                width: 0.5,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      // Nombre de la paleta
                      Text(
                        getPaletteName(palette),
                        style: TextStyle(
                          color: isSelected ? appColors.primary : appColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                      // Indicador de seleccion
                      if (isSelected) ...[
                        const SizedBox(height: 6),
                        Icon(
                          Icons.check_circle,
                          color: appColors.primary,
                          size: 18,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          // Seccion Multimoneda
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Multimoneda',
              style: TextStyle(
                color: appColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Card de Multimoneda
          const _MultiCurrencyCard(),

          const SizedBox(height: 28),

          // Seccion Formato de Números
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Formato de Números',
              style: TextStyle(
                color: appColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _DecimalSeparatorCard(),

          const SizedBox(height: 32),

          // Informacion de la version
          Center(
            child: Text(
              'FinApp v1.0.0',
              style: TextStyle(
                color: appColors.textDisabled,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final appColors = AppColors.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? appColors.primary.withAlpha(25)
              : appColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? appColors.primary : appColors.borderSubtle,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? appColors.primary : appColors.textSecondary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? appColors.primary : appColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card selector de separador decimal
class _DecimalSeparatorCard extends ConsumerWidget {
  const _DecimalSeparatorCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = AppColors.of(context);
    final decimalSep = ref.watch(decimalSeparatorProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Separador decimal',
            style: TextStyle(
              color: appColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOption(
                  context: context,
                  label: '1,000.50',
                  sublabel: 'Punto  ( . )',
                  value: '.',
                  selected: decimalSep == '.',
                  onTap: () => ref
                      .read(decimalSeparatorProvider.notifier)
                      .setSeparator('.'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOption(
                  context: context,
                  label: '1.000,50',
                  sublabel: 'Coma  ( , )',
                  value: ',',
                  selected: decimalSep == ',',
                  onTap: () => ref
                      .read(decimalSeparatorProvider.notifier)
                      .setSeparator(','),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required String label,
    required String sublabel,
    required String value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final appColors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? appColors.primary.withAlpha(25) : appColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? appColors.primary : appColors.borderSubtle,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? appColors.primary : appColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sublabel,
              style: TextStyle(
                color: selected ? appColors.primary : appColors.textSecondary,
                fontSize: 11,
              ),
            ),
            if (selected) ...[
              const SizedBox(height: 6),
              Icon(Icons.check_circle, color: appColors.primary, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}

/// Card de configuracion multimoneda
class _MultiCurrencyCard extends ConsumerStatefulWidget {
  const _MultiCurrencyCard();

  @override
  ConsumerState<_MultiCurrencyCard> createState() => _MultiCurrencyCardState();
}

class _MultiCurrencyCardState extends ConsumerState<_MultiCurrencyCard> {
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final rateAsync = ref.watch(currentExchangeRateProvider);
    final isEnabled = ref.watch(isMultiCurrencyEnabledProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle de activacion
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'USD / Bolivares',
                      style: TextStyle(
                        color: appColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mostrar montos en ambas monedas',
                      style: TextStyle(
                        color: appColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: (value) async {
                  final service = ref.read(exchangeRateServiceProvider);
                  final settings = await service.getCurrencySettings();
                  settings.isMultiCurrencyEnabled = value;
                  await service.saveCurrencySettings(settings);

                  // Si se habilita, intentar obtener la tasa
                  if (value) {
                    setState(() => _isRefreshing = true);
                    await service.fetchAndCacheRate();
                    ref.invalidate(currentExchangeRateProvider);
                    if (mounted) setState(() => _isRefreshing = false);
                  }
                },
              ),
            ],
          ),

          // Detalles de tasa (solo si esta habilitado)
          if (isEnabled) ...[
            const SizedBox(height: 16),
            Divider(color: appColors.borderSubtle),
            const SizedBox(height: 12),

            // Tasa actual
            rateAsync.when(
              data: (rate) {
                if (rate == null) {
                  return _buildRateError(appColors);
                }
                return _buildRateInfo(appColors, rate.rate, rate.date, rate.source);
              },
              loading: () => _buildRateLoading(appColors),
              error: (_, __) => _buildRateError(appColors),
            ),

            const SizedBox(height: 12),

            // Boton de refrescar
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isRefreshing ? null : _refreshRate,
                icon: _isRefreshing
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: appColors.primary,
                        ),
                      )
                    : Icon(Icons.refresh, size: 18, color: appColors.primary),
                label: Text(
                  _isRefreshing ? 'Actualizando...' : 'Actualizar tasa',
                  style: TextStyle(color: appColors.primary, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: appColors.borderSubtle),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRateInfo(AppColors appColors, double rate, DateTime date, String source) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm', 'es').format(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tasa
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: appColors.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: appColors.primary.withAlpha(40)),
          ),
          child: Row(
            children: [
              Icon(Icons.currency_exchange, color: appColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '1 USD = ${rate.toStringAsFixed(2)} BS',
                  style: TextStyle(
                    color: appColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: appColors.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  source,
                  style: TextStyle(
                    color: appColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Ultima actualizacion
        Row(
          children: [
            Icon(Icons.access_time, size: 12, color: appColors.textDisabled),
            const SizedBox(width: 4),
            Text(
              'Actualizado: $dateStr',
              style: TextStyle(
                color: appColors.textDisabled,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRateLoading(AppColors appColors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: appColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildRateError(AppColors appColors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: appColors.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: appColors.warning.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: appColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No se pudo obtener la tasa. Presiona actualizar.',
              style: TextStyle(
                color: appColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshRate() async {
    setState(() => _isRefreshing = true);
    final service = ref.read(exchangeRateServiceProvider);
    await service.fetchAndCacheRate();
    ref.invalidate(currentExchangeRateProvider);
    if (mounted) setState(() => _isRefreshing = false);
  }
}
