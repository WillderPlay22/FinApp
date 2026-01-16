import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../data/models/debt.dart'; // Import Debt model
import '../../../logic/providers/database_providers.dart'; // For debtDaoProvider
import '../../../logic/providers/time_provider.dart'; // For nowProvider
import 'package:intl/intl.dart'; // For date formatting

// Enum para la frecuencia de pago
enum DebtFrequency {
  daily,
  weekly,
  biweekly, // Cada 2 semanas
  fortnightly, // Quincenal
  monthly,
  custom, // Cada X días
}

class AddDebtModal extends ConsumerStatefulWidget {
  const AddDebtModal({super.key});

  @override
  ConsumerState<AddDebtModal> createState() => _AddDebtModalState();
}

class _AddDebtModalState extends ConsumerState<AddDebtModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController(text: "Nueva Deuda");
  final _totalAmountController = TextEditingController();
  final _initialPaymentController = TextEditingController();
  final _installmentCountController = TextEditingController();
  final _installmentAmountController = TextEditingController();
  final _customDaysController = TextEditingController();

  // FocusNodes para saber qué campo está editando el usuario
  final _totalAmountFocus = FocusNode();
  final _installmentCountFocus = FocusNode();
  final _installmentAmountFocus = FocusNode();
  final _initialPaymentFocus = FocusNode();

  DebtFrequency _frequency = DebtFrequency.monthly;

  // Para evitar bucles infinitos en los listeners
  bool _isUpdating = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _totalAmountController.addListener(_recalculate);
    _initialPaymentController.addListener(_recalculate);
    _installmentCountController.addListener(_recalculate);
    _installmentAmountController.addListener(_recalculate);
    // Add listeners to focus nodes to trigger recalculation when focus changes
    _totalAmountFocus.addListener(_recalculate);
    _installmentCountFocus.addListener(_recalculate);
    _installmentAmountFocus.addListener(_recalculate);
    _initialPaymentFocus.addListener(_recalculate);
    
    _titleController.addListener(_validateForm);
    _totalAmountController.addListener(_validateForm);
    _installmentCountController.addListener(_validateForm);
    _installmentAmountController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _totalAmountController.dispose();
    _initialPaymentController.dispose();
    _installmentCountController.dispose();
    _installmentAmountController.dispose();
    _customDaysController.dispose();
    _totalAmountFocus.removeListener(_recalculate);
    _installmentCountFocus.removeListener(_recalculate);
    _installmentAmountFocus.removeListener(_recalculate);
    _initialPaymentFocus.removeListener(_recalculate);
    
    _titleController.removeListener(_validateForm);
    _totalAmountController.removeListener(_validateForm);
    _installmentCountController.removeListener(_validateForm);
    _installmentAmountController.removeListener(_validateForm);
    
    _totalAmountFocus.dispose();
    _installmentCountFocus.dispose();
    _installmentAmountFocus.dispose();
    _initialPaymentFocus.dispose();
    super.dispose();
  }

  void _validateForm() {
    final isValid = _titleController.text.isNotEmpty &&
        _totalAmountController.text.isNotEmpty &&
        _installmentCountController.text.isNotEmpty &&
        _installmentAmountController.text.isNotEmpty;
        
    if (isValid != _isFormValid) setState(() => _isFormValid = isValid);
  }

  void _recalculate() {
    if (_isUpdating) return;
    _isUpdating = true;

    final totalAmount = double.tryParse(_totalAmountController.text);
    final initialPayment = double.tryParse(_initialPaymentController.text) ?? 0.0;
    final count = int.tryParse(_installmentCountController.text);
    final amount = double.tryParse(_installmentAmountController.text);

    final isEditingTotal = _totalAmountFocus.hasFocus;
    final isEditingCount = _installmentCountFocus.hasFocus;
    final isEditingAmount = _installmentAmountFocus.hasFocus;
    final isEditingInitialPayment = _initialPaymentFocus.hasFocus;

    // If user is editing a field, it becomes the source of truth.
    // We then check if we have one other piece of information to calculate the third.
    if (isEditingTotal || isEditingInitialPayment) {
        // User sets Total. If Count exists, calculate Amount.
        if (totalAmount != null && count != null && count > 0) {
            final remaining = totalAmount - initialPayment;
            final newAmount = remaining > 0 ? remaining / count : 0.0;
            _updateText(_installmentAmountController, newAmount.toStringAsFixed(2));
        }
    } else if (isEditingCount) {
        // User sets Count.
        // Priority 1: If Total exists, it's the anchor. Calculate Amount.
        if (count != null && count > 0 && totalAmount != null) {
            final remaining = totalAmount - initialPayment;
            final newAmount = remaining > 0 ? remaining / count : 0.0;
            _updateText(_installmentAmountController, newAmount.toStringAsFixed(2));
        } 
        // Priority 2: If Amount exists, calculate Total.
        else if (count != null && count > 0 && amount != null && amount > 0) {
            final newTotal = (count * amount) + initialPayment;
            _updateText(_totalAmountController, newTotal.toStringAsFixed(2));
        }
    } else if (isEditingAmount) {
        // User sets Amount.
        // Priority 1: If Total exists, it's the anchor. Calculate Count.
        if (amount != null && amount > 0 && totalAmount != null) {
            final remaining = totalAmount - initialPayment;
            if (remaining > 0) {
                final newCount = (remaining / amount).ceil();
                _updateText(_installmentCountController, newCount.toString());
            }
        }
        // Priority 2: If Count exists, calculate Total.
        else if (amount != null && amount > 0 && count != null && count > 0) {
            final newTotal = (count * amount) + initialPayment;
            _updateText(_totalAmountController, newTotal.toStringAsFixed(2));
        }
    }

    _isUpdating = false;
  }

  void _updateText(TextEditingController controller, String newText) {
    // Only update if the text is actually different to prevent cursor jumping
    if (controller.text != newText) {
      controller.text = newText;
    }
  }

  void _showSummary() {
    // Basic validation before showing summary
    if (!_formKey.currentState!.validate()) return;

    // Lógica para mostrar el resumen antes de guardar
    final total = double.tryParse(_totalAmountController.text) ?? 0;
    final count = int.tryParse(_installmentCountController.text) ?? 0;
    final amount = double.tryParse(_installmentAmountController.text) ?? 0.0;
    final initialPayment = double.tryParse(_initialPaymentController.text) ?? 0.0;
    final customDays = int.tryParse(_customDaysController.text);

    final debtDao = ref.read(debtDaoProvider);
    final now = ref.read(nowProvider);
    final estimatedDueDate = debtDao.calculateDueDate(now, count, _frequency, customDays);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Resumen de la Deuda"),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Título: ${_titleController.text}"),
            Text("Monto Total: \$${total.toStringAsFixed(2)}"),
            Text("Pago Inicial: \$${initialPayment.toStringAsFixed(2)}"),
            Text("Cuotas: $count de \$${amount.toStringAsFixed(2)} c/u"), // Use c/u for "cada una"
            Text("Frecuencia: ${_frequency.name}"),
            if (_frequency == DebtFrequency.custom && _customDaysController.text.isNotEmpty) Text("Cada ${_customDaysController.text} días"),
            Text("Fecha estimada de fin: ${DateFormat('dd MMM yyyy', 'es').format(estimatedDueDate)}"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              // Primero se cierra el diálogo de resumen.
              Navigator.pop(ctx);
              // Luego se intenta guardar. La función se encargará de la validación y de cerrar el modal principal.
              _saveDebt();
            },
            child: const Text("Registrar")),
        ],
      ),
    );
  }

  Future<void> _saveDebt() async {
    if (!_formKey.currentState!.validate()) return;

    final debtDao = ref.read(debtDaoProvider);
    final now = ref.read(nowProvider);

    final totalAmount = double.tryParse(_totalAmountController.text) ?? 0.0;
    final initialPayment = double.tryParse(_initialPaymentController.text) ?? 0.0;
    final installmentCount = int.tryParse(_installmentCountController.text) ?? 0;
    final installmentAmount = double.tryParse(_installmentAmountController.text) ?? 0.0;
    final customDays = int.tryParse(_customDaysController.text);

    // Basic validation
    if (totalAmount <= 0 || installmentCount <= 0 || installmentAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Por favor, completa los campos de monto y cuotas.")));
      return;
    }

    final remainingAmount = totalAmount - initialPayment;

    final debt = Debt()
      ..title = _titleController.text
      ..totalAmount = totalAmount
      ..initialPayment = initialPayment
      ..remainingAmount = remainingAmount
      ..installmentCount = installmentCount
      ..installmentAmount = installmentAmount
      ..originalInstallmentAmount = installmentAmount // Set the baseline
      ..frequency = _frequency
      ..customDays = customDays
      ..creationDate = now
      ..nextPaymentDate = debtDao.calculateNextPaymentDate(now, _frequency, customDays) // Calculate first payment date
      ..dueDate = debtDao.calculateDueDate(now, installmentCount, _frequency, customDays); // Calculate estimated due date

    await debtDao.saveDebt(debt);

    if (mounted) {
      // El diálogo de resumen ya fue cerrado por el botón.
      Navigator.pop(context); // Close AddDebtModal
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Deuda registrada con éxito.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Registrar Deuda", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.primary), textAlign: TextAlign.center),
              const Gap(20),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Título de la deuda (Ej: Préstamo coche)",
                  filled: true,
                  fillColor: colors.surfaceContainerHighest,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const Gap(20),
              
              // --- SECCIÓN DE CÁLCULO ---
              _buildCalculationSection(colors),
              const Gap(20),

              // --- SECCIÓN DE FRECUENCIA ---
              _buildFrequencySection(),
              const Gap(30),

              ElevatedButton(
                onPressed: _isFormValid ? _showSummary : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD35400), // Terracota
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text("Registrar Deuda"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(ColorScheme colors, String label, {String? prefix}) {
    return InputDecoration(
      labelText: label,
      prefixText: prefix,
      filled: true,
      fillColor: colors.surfaceContainerHighest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    );
  }

  Widget _buildCalculationSection(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Parámetros de la Deuda", style: TextStyle(fontWeight: FontWeight.bold)),
          const Gap(10),
          Row(
            children: [
              Expanded(child: TextFormField(controller: _totalAmountController, focusNode: _totalAmountFocus, decoration: _inputDecoration(colors, "Monto Total", prefix: "\$"), keyboardType: TextInputType.number)),
              const Gap(10),
              Expanded(child: TextFormField(controller: _initialPaymentController, focusNode: _initialPaymentFocus, decoration: _inputDecoration(colors, "Pago Inicial", prefix: "\$"), keyboardType: TextInputType.number)),
            ],
          ),
          const Gap(15),
          Row(
            children: [
              Expanded(child: TextFormField(controller: _installmentCountController, focusNode: _installmentCountFocus, decoration: _inputDecoration(colors, "Cuotas"), keyboardType: TextInputType.number)),
              const Gap(10),
              Expanded(child: TextFormField(controller: _installmentAmountController, focusNode: _installmentAmountFocus, decoration: _inputDecoration(colors, "Monto Cuota", prefix: "\$"), keyboardType: TextInputType.number)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencySection() {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Frecuencia de Pago", style: TextStyle(fontWeight: FontWeight.bold)),
        const Gap(10),
        DropdownButtonFormField<DebtFrequency>(
          decoration: _inputDecoration(colors, "Selecciona Frecuencia"), // Use consistent input decoration
          initialValue: _frequency,
          items: const [
            DropdownMenuItem(value: DebtFrequency.daily, child: Text("Diaria")),
            DropdownMenuItem(value: DebtFrequency.weekly, child: Text("Semanal")),
            DropdownMenuItem(value: DebtFrequency.biweekly, child: Text("Cada 2 semanas")),
            DropdownMenuItem(value: DebtFrequency.fortnightly, child: Text("Quincenal (15 y fin de mes)")),
            DropdownMenuItem(value: DebtFrequency.monthly, child: Text("Mensual")),
            DropdownMenuItem(value: DebtFrequency.custom, child: Text("Personalizado (cada X días)")),
          ],
          onChanged: (v) => setState(() => _frequency = v!),
        ),
        if (_frequency == DebtFrequency.custom) ...[
          const Gap(10),
          TextFormField(
            controller: _customDaysController,
            decoration: _inputDecoration(colors, "Pagar cada (días)", prefix: "Cada ").copyWith(suffixText: "días"),
            keyboardType: TextInputType.number,
          ),
        ]
      ],
    );
  }
}

extension DebtFrequencyExtension on DebtFrequency {
  String get name {
    switch (this) {
      case DebtFrequency.daily:
        return "Diaria";
      case DebtFrequency.weekly:
        return "Semanal";
      case DebtFrequency.biweekly:
        return "Cada 2 semanas";
      case DebtFrequency.fortnightly:
        return "Quincenal";
      case DebtFrequency.monthly:
        return "Mensual";
      case DebtFrequency.custom:
        return "Personalizado";
    }
  }
}
