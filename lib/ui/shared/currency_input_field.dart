import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme/app_colors.dart';
import '../../logic/providers/currency_providers.dart';
import '../../logic/providers/decimal_separator_provider.dart';
import 'amount_input_formatter.dart';

/// Campo de entrada de montos con soporte multi-moneda.
///
/// Cuando multi-moneda esta habilitado, muestra un selector para alternar
/// entre USD y BS, y auto-convierte mostrando el equivalente debajo.
/// Cuando esta deshabilitado, funciona como un TextField normal de monto.
class CurrencyInputField extends ConsumerStatefulWidget {
  /// Controlador del texto (contiene el monto en la moneda seleccionada).
  final TextEditingController controller;

  /// Hint text del campo.
  final String? hintText;

  /// Estilo del texto del campo.
  final TextStyle? style;

  /// Color del icono de moneda.
  final Color? iconColor;

  /// Callback cuando cambia la moneda seleccionada.
  final ValueChanged<String>? onCurrencyChanged;

  /// Moneda inicial seleccionada.
  final String initialCurrency;

  /// Si el campo esta en modo solo lectura.
  final bool readOnly;

  /// Monto maximo permitido (para validaciones).
  final double? maxAmount;

  const CurrencyInputField({
    super.key,
    required this.controller,
    this.hintText,
    this.style,
    this.iconColor,
    this.onCurrencyChanged,
    this.initialCurrency = 'USD',
    this.readOnly = false,
    this.maxAmount,
  });

  @override
  ConsumerState<CurrencyInputField> createState() => _CurrencyInputFieldState();
}

class _CurrencyInputFieldState extends ConsumerState<CurrencyInputField> {
  late String _selectedCurrency;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.initialCurrency;
  }

  @override
  Widget build(BuildContext context) {
    final isMultiCurrency = ref.watch(isMultiCurrencyEnabledProvider);
    final decimalSep = ref.watch(decimalSeparatorProvider);
    final appColors = AppColors.of(context);
    final iconColor = widget.iconColor ?? const Color(0xFFE74C3C);

    if (!isMultiCurrency) {
      // Sin multi-moneda: campo normal
      return TextField(
        controller: widget.controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [AmountInputFormatter(decimalSeparator: decimalSep)],
        textAlign: TextAlign.center,
        readOnly: widget.readOnly,
        style: widget.style ??
            TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: iconColor,
            ),
        decoration: InputDecoration(
          hintText: widget.maxAmount != null
              ? "Max ${widget.maxAmount}"
              : (widget.hintText ?? "0.00"),
          prefixIcon: Icon(Icons.attach_money, color: iconColor),
          border: InputBorder.none,
          hintStyle: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .outline
                .withAlpha((255 * 0.3).round()),
          ),
        ),
      );
    }

    // Con multi-moneda: campo con selector de moneda y conversion
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selector de moneda
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CurrencyToggle(
              label: 'USD',
              symbol: '\$',
              isSelected: _selectedCurrency == 'USD',
              onTap: () => _switchCurrency('USD'),
              appColors: appColors,
            ),
            const SizedBox(width: 8),
            _CurrencyToggle(
              label: 'BS',
              symbol: 'Bs.',
              isSelected: _selectedCurrency == 'BS',
              onTap: () => _switchCurrency('BS'),
              appColors: appColors,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Campo de monto
        TextField(
          controller: widget.controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [AmountInputFormatter(decimalSeparator: decimalSep)],
          textAlign: TextAlign.center,
          readOnly: widget.readOnly,
          style: widget.style ??
              TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: iconColor,
              ),
          decoration: InputDecoration(
            hintText: widget.maxAmount != null
                ? "Max ${widget.maxAmount}"
                : (widget.hintText ?? "0.00"),
            prefixIcon: Icon(
              _selectedCurrency == 'USD'
                  ? Icons.attach_money
                  : Icons.currency_exchange,
              color: iconColor,
            ),
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withAlpha((255 * 0.3).round()),
            ),
          ),
        ),

        // Equivalente en la otra moneda
        _ConversionPreview(
          controller: widget.controller,
          selectedCurrency: _selectedCurrency,
          appColors: appColors,
        ),
      ],
    );
  }

  void _switchCurrency(String currency) {
    if (_selectedCurrency != currency) {
      setState(() => _selectedCurrency = currency);
      widget.onCurrencyChanged?.call(currency);
    }
  }
}

class _CurrencyToggle extends StatelessWidget {
  final String label;
  final String symbol;
  final bool isSelected;
  final VoidCallback onTap;
  final AppColors appColors;

  const _CurrencyToggle({
    required this.label,
    required this.symbol,
    required this.isSelected,
    required this.onTap,
    required this.appColors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? appColors.primary.withAlpha(25)
              : appColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? appColors.primary : appColors.borderSubtle,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          '$symbol $label',
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? appColors.primary : appColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Widget que muestra la conversion en tiempo real del monto ingresado.
class _ConversionPreview extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String selectedCurrency;
  final AppColors appColors;

  const _ConversionPreview({
    required this.controller,
    required this.selectedCurrency,
    required this.appColors,
  });

  @override
  ConsumerState<_ConversionPreview> createState() => _ConversionPreviewState();
}

class _ConversionPreviewState extends ConsumerState<_ConversionPreview> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final rateAsync = ref.watch(currentExchangeRateProvider);
    final decimalSep = ref.watch(decimalSeparatorProvider);
    final amount = parseAmount(widget.controller.text, decimalSep);

    if (amount <= 0) {
      return const SizedBox(height: 16);
    }

    return rateAsync.when(
      data: (rate) {
        if (rate == null) return const SizedBox(height: 16);

        double converted;
        String prefix;

        if (widget.selectedCurrency == 'USD') {
          converted = amount * rate.rate;
          prefix = 'Bs. ';
        } else {
          converted = amount / rate.rate;
          prefix = '\$';
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            '$prefix${converted.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              color: widget.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
      loading: () => const SizedBox(height: 16),
      error: (_, __) => const SizedBox(height: 16),
    );
  }
}
