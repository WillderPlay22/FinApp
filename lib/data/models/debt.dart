import 'package:isar/isar.dart';
import 'package:finapp/ui/expenses/modals/add_debt_modal.dart'; // Import DebtFrequency

part 'debt.g.dart';

@collection
class Debt {
  Id id = Isar.autoIncrement;

  late String title;
  late double totalAmount;
  late double initialPayment;
  late double remainingAmount;
  late int installmentCount;
  late double installmentAmount;
  double? originalInstallmentAmount; // The baseline installment amount
  @enumerated
  late DebtFrequency frequency; // Stored as int
  int? customDays; // For custom frequency

  late DateTime creationDate;
  DateTime? nextPaymentDate;
  DateTime? dueDate; // Estimated date when debt will be paid off
  bool isPaidOff = false;

  // --- MULTI-MONEDA ---
  /// Código de moneda de los montos (null = moneda de referencia para retrocompatibilidad).
  String? currencyCode;
}