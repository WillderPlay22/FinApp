import 'package:flutter/services.dart';

/// Convierte el texto formateado de un campo de monto a double.
/// Elimina los separadores de miles y normaliza el separador decimal a '.'.
double parseAmount(String text, String decimalSep) {
  if (text.isEmpty) return 0.0;
  final thousandsSep = decimalSep == '.' ? ',' : '.';
  final cleaned = text
      .replaceAll(thousandsSep, '')
      .replaceAll(decimalSep, '.');
  return double.tryParse(cleaned) ?? 0.0;
}

/// Formatea en tiempo real un campo de entrada de monto:
/// - Solo permite dígitos y UN separador decimal ([decimalSeparator]).
/// - Añade automáticamente separadores de miles (el opuesto al decimal).
/// - Cursor siempre al final.
class AmountInputFormatter extends TextInputFormatter {
  final String decimalSeparator;

  const AmountInputFormatter({required this.decimalSeparator});

  String get _thousandsSep => decimalSeparator == '.' ? ',' : '.';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;

    // Campo vacío: no hacer nada
    if (raw.isEmpty) return newValue;

    // 1. Quitar separadores de miles que el usuario haya pegado
    final withoutThousands = raw.replaceAll(_thousandsSep, '');

    // 2. Recorrer carácter a carácter: conservar dígitos y el PRIMER decimal
    final buffer = StringBuffer();
    bool hasDecimal = false;
    for (final ch in withoutThousands.split('')) {
      if (RegExp(r'\d').hasMatch(ch)) {
        buffer.write(ch);
      } else if (ch == decimalSeparator && !hasDecimal) {
        hasDecimal = true;
        buffer.write(ch);
      }
      // Cualquier otro carácter se descarta
    }
    final cleaned = buffer.toString();

    // 3. Separar parte entera y decimal
    final sepIndex = cleaned.indexOf(decimalSeparator);
    final String intPart;
    final String decPart; // incluye el separador si existe, e.g. ",89"

    if (sepIndex == -1) {
      intPart = cleaned;
      decPart = '';
    } else {
      intPart = cleaned.substring(0, sepIndex);
      decPart = cleaned.substring(sepIndex); // ej. ",89" o ","
    }

    // 4. Formatear la parte entera con separadores de miles
    final formatted = _formatIntPart(intPart);

    // 5. Rearmar
    final result = formatted + decPart;

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }

  /// Añade el separador de miles a la parte entera cada 3 dígitos desde la derecha.
  String _formatIntPart(String intPart) {
    if (intPart.isEmpty) return '';
    // Invertir, agrupar de a 3, insertar separador, volver a invertir
    final reversed = intPart.split('').reversed.join();
    final chunks = <String>[];
    for (int i = 0; i < reversed.length; i += 3) {
      final end = (i + 3).clamp(0, reversed.length);
      chunks.add(reversed.substring(i, end));
    }
    return chunks.join(_thousandsSep).split('').reversed.join();
  }
}
