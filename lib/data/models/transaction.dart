import 'package:isar/isar.dart';
import 'enums.dart';
import 'expense.dart';
import 'debt.dart';
import 'saving.dart';

part 'transaction.g.dart'; 

@collection
class FinancialTransaction {
  Id id = Isar.autoIncrement; 

  late double amount; 

  late String note; 

  // Agregamos @Index() aquí para que filtrar por mes/año sea ultra rápido
  @Index()
  late DateTime date; 

  @Enumerated(EnumType.name)
  late TransactionType type; 

  // --- DATOS VISUALES ---
  late String categoryName;   
  late int categoryIconCode;  
  late int colorValue;        

  // --- VINCULACIÓN (NUEVO) ---
  // Si este campo tiene valor, significa que esta transacción
  // nació de un Ingreso Fijo (RecurringMovement).
  // Si es NULL, es un ingreso/gasto manual (Extra).
  @Index()
  int? parentRecurringId;

  // --- VINCULACIÓN GASTOS (NUEVO) ---
  bool isRecurring = false;

  // Enlaza esta transacción al gasto fijo original que la generó.
  final relatedExpense = IsarLink<Expense>();

  // Enlaza esta transacción a la deuda original que la generó.
  final relatedDebt = IsarLink<Debt>();

  // Enlaza esta transacción al ahorro original (si aplica).
  final relatedSaving = IsarLink<Saving>();

  // --- MULTI-MONEDA ---
  /// Código de moneda en la que se registró el monto (null = moneda de referencia para retrocompatibilidad).
  String? currencyCode;

  /// Tasa de cambio al momento de ejecutar/confirmar esta transacción.
  double? exchangeRateAtTime;

  /// Monto pre-calculado en la moneda de referencia (USD).
  double? amountInReferenceCurrency;

  /// Monto pre-calculado en la moneda local (BS).
  double? amountInLocalCurrency;

  // --- SPLIT PAYMENT ---
  /// Modo de pago: cómo se pagó esta transacción.
  @Enumerated(EnumType.name)
  PaymentMode? paymentMode;

  /// Porción fija pagada en moneda referencial (USD). No cambia después de confirmar.
  double? fixedReferencePortion;

  /// Porción fija pagada en moneda local (BS). No cambia después de confirmar.
  double? fixedLocalPortion;

  /// Retorna el monto en moneda de referencia (USD).
  /// Usa el monto pre-calculado si existe, sino asume que amount ya está en referencia.
  @ignore
  double get referenceAmount => amountInReferenceCurrency ?? amount;

  /// Monto en referencia (USD) sensible a la tasa actual.
  /// Recalcula la porción en BS usando [currentRate].
  double referenceAmountWithRate(double? currentRate) {
    final mode = paymentMode;
    if (mode == null || mode == PaymentMode.singleCurrency) {
      if (amountInReferenceCurrency != null) return amountInReferenceCurrency!;
      // Si no hay amountInReferenceCurrency, convertir BS usando tasa actual
      if (currencyCode == 'BS' && currentRate != null && currentRate > 0) {
        return amount / currentRate;
      }
      return amount;
    }
    if (mode == PaymentMode.allReference) {
      return fixedReferencePortion ?? amount;
    }
    if (mode == PaymentMode.allLocal) {
      if (currentRate != null && currentRate > 0 && fixedLocalPortion != null) {
        return fixedLocalPortion! / currentRate;
      }
      return amountInReferenceCurrency ?? amount;
    }
    if (mode == PaymentMode.mixed) {
      final usdPart = fixedReferencePortion ?? 0.0;
      final bsPart = fixedLocalPortion ?? 0.0;
      if (currentRate != null && currentRate > 0) {
        return usdPart + (bsPart / currentRate);
      }
      return amountInReferenceCurrency ?? amount;
    }
    return amountInReferenceCurrency ?? amount;
  }

  /// Monto en moneda local (BS) sensible a la tasa actual.
  double localAmountWithRate(double? currentRate) {
    final mode = paymentMode;
    if (mode == null || mode == PaymentMode.singleCurrency) {
      return amountInLocalCurrency ?? (currentRate != null ? amount * currentRate : amount);
    }
    if (mode == PaymentMode.allLocal) {
      return fixedLocalPortion ?? amount;
    }
    if (mode == PaymentMode.allReference) {
      if (currentRate != null && fixedReferencePortion != null) {
        return fixedReferencePortion! * currentRate;
      }
      return amountInLocalCurrency ?? amount;
    }
    if (mode == PaymentMode.mixed) {
      final usdPart = fixedReferencePortion ?? 0.0;
      final bsPart = fixedLocalPortion ?? 0.0;
      if (currentRate != null) {
        return (usdPart * currentRate) + bsPart;
      }
      return amountInLocalCurrency ?? amount;
    }
    return amountInLocalCurrency ?? amount;
  }

  // Constructor vacío para la creación de instancias sin parámetros.
  FinancialTransaction();
}