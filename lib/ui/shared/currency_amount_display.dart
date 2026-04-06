import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/providers/currency_providers.dart';

/// Widget reutilizable para mostrar montos con soporte dual de moneda.
///
/// Cuando multi-moneda esta habilitado, muestra el monto principal grande
/// y el equivalente en la otra moneda mas pequeno debajo.
/// Cuando esta deshabilitado, muestra solo el monto como siempre.
class CurrencyAmountDisplay extends ConsumerWidget {
  /// Monto en moneda de referencia (USD).
  final double amount;

  /// Codigo de moneda del monto (null = USD por defecto).
  final String? currencyCode;

  /// Estilo para el monto principal.
  final TextStyle? primaryStyle;

  /// Estilo para el monto secundario (conversion).
  final TextStyle? secondaryStyle;

  /// Prefijo personalizado (si no se usa, se auto-determina por moneda).
  final String? prefix;

  /// Alineacion del texto.
  final TextAlign textAlign;

  /// Si se debe mostrar el signo $ o Bs. como prefijo.
  final bool showCurrencySymbol;

  const CurrencyAmountDisplay({
    super.key,
    required this.amount,
    this.currencyCode,
    this.primaryStyle,
    this.secondaryStyle,
    this.prefix,
    this.textAlign = TextAlign.start,
    this.showCurrencySymbol = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMultiCurrency = ref.watch(isMultiCurrencyEnabledProvider);
    final effectiveCurrency = currencyCode ?? 'USD';

    // Formato del monto principal
    final primaryPrefix = prefix ?? _getCurrencyPrefix(effectiveCurrency);
    final primaryText = '$primaryPrefix${amount.toStringAsFixed(2)}';

    if (!isMultiCurrency) {
      // Sin multi-moneda: mostrar solo el monto con $
      return Text(
        showCurrencySymbol ? '\$${amount.toStringAsFixed(2)}' : amount.toStringAsFixed(2),
        style: primaryStyle,
        textAlign: textAlign,
      );
    }

    // Con multi-moneda: mostrar ambos montos
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: textAlign == TextAlign.center
          ? CrossAxisAlignment.center
          : textAlign == TextAlign.end
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
      children: [
        Text(
          primaryText,
          style: primaryStyle,
          textAlign: textAlign,
        ),
        _SecondaryAmountText(
          amount: amount,
          currencyCode: effectiveCurrency,
          style: secondaryStyle,
          textAlign: textAlign,
        ),
      ],
    );
  }

  String _getCurrencyPrefix(String currency) {
    switch (currency) {
      case 'BS':
        return 'Bs. ';
      case 'USD':
      default:
        return '\$';
    }
  }
}

/// Widget interno que calcula y muestra el monto convertido.
class _SecondaryAmountText extends ConsumerWidget {
  final double amount;
  final String currencyCode;
  final TextStyle? style;
  final TextAlign textAlign;

  const _SecondaryAmountText({
    required this.amount,
    required this.currencyCode,
    this.style,
    required this.textAlign,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rateAsync = ref.watch(currentExchangeRateProvider);

    return rateAsync.when(
      data: (rate) {
        if (rate == null) return const SizedBox.shrink();

        double convertedAmount;
        String convertedPrefix;

        if (currencyCode == 'USD') {
          // Mostrar equivalente en BS
          convertedAmount = amount * rate.rate;
          convertedPrefix = 'Bs. ';
        } else {
          // Mostrar equivalente en USD
          convertedAmount = amount / rate.rate;
          convertedPrefix = '\$';
        }

        final defaultStyle = TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.outline,
          fontWeight: FontWeight.w400,
        );

        return Text(
          '$convertedPrefix${convertedAmount.toStringAsFixed(2)}',
          style: style ?? defaultStyle,
          textAlign: textAlign,
        );
      },
      loading: () => const SizedBox(height: 12),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
