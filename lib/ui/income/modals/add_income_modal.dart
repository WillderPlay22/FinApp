import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../data/models/enums.dart';
import '../../../data/models/transaction.dart';
import '../../../data/models/recurring_movement.dart';
import '../../../logic/providers/database_providers.dart';
// ✅ IMPORTANTE: Conexión con notificaciones
import '../../../logic/services/notification_service.dart';

class AddIncomeModal extends ConsumerStatefulWidget {
  const AddIncomeModal({super.key});

  @override
  ConsumerState<AddIncomeModal> createState() => _AddIncomeModalState();
}

class _AddIncomeModalState extends ConsumerState<AddIncomeModal> {
  bool _isRecurring = false;
  final TextEditingController _titleController = TextEditingController();

  // Variables Eventual
  final TextEditingController _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  // Variables Recurrente
  Frequency _selectedFrequency = Frequency.biweekly;
  int _selectedDayOfWeek = 1; 
  int _selectedDayOfMonth = 1;
  final TextEditingController _amount15Controller = TextEditingController();
  final TextEditingController _amountLastController = TextEditingController();
  final TextEditingController _recurringAmountController = TextEditingController();
  bool _isDailyVariable = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TITULO Y SWITCH
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isRecurring ? "Ingreso Fijo" : "Ingreso Extra",
                  style: textStyles.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Text("Extra", style: TextStyle(
                      fontWeight: !_isRecurring ? FontWeight.bold : FontWeight.normal,
                      color: !_isRecurring ? colors.primary : colors.outline
                    )),
                    Switch(
                      value: _isRecurring,
                      onChanged: (value) => setState(() => _isRecurring = value),
                      activeColor: colors.primary,
                    ),
                    Text("Fijo", style: TextStyle(
                      fontWeight: _isRecurring ? FontWeight.bold : FontWeight.normal,
                      color: _isRecurring ? colors.primary : colors.outline
                    )),
                  ],
                ),
              ],
            ),
            
            const Divider(),
            const Gap(10),

            if (_isRecurring) 
              _buildRecurringForm(colors) 
            else 
              _buildEventualForm(colors),
            
            const Gap(20),

            ElevatedButton(
              onPressed: _saveData,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("GUARDAR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // LÓGICA DE GUARDADO (ACTUALIZADA CON NOTIFICACIONES)
  // ===========================================================================
  void _saveData() async {
    // 1. Validaciones básicas
    if (!_isRecurring && _amountController.text.isEmpty) return;
    if (_isRecurring && _titleController.text.isEmpty) return;

    try {
      if (_isRecurring) {
        // --- GUARDAR INGRESO FIJO ---
        final recurringDao = ref.read(recurringDaoProvider);
        
        List<int> paymentDays = [];
        List<double> paymentAmounts = [];
        double accumulated = 0;

        if (_selectedFrequency == Frequency.biweekly) {
          paymentDays = [15, -1]; 
          final m15 = double.tryParse(_amount15Controller.text) ?? 0;
          final mLast = double.tryParse(_amountLastController.text) ?? 0;
          paymentAmounts = [m15, mLast];
        } else if (_selectedFrequency == Frequency.monthly) {
          paymentDays = [_selectedDayOfMonth];
          paymentAmounts = [double.tryParse(_recurringAmountController.text) ?? 0];
        } else if (_selectedFrequency == Frequency.weekly) {
          paymentDays = [_selectedDayOfWeek];
          paymentAmounts = [double.tryParse(_recurringAmountController.text) ?? 0];
        } else if (_selectedFrequency == Frequency.daily) {
          if (!_isDailyVariable) {
             paymentAmounts = [double.tryParse(_recurringAmountController.text) ?? 0];
          } else {
            accumulated = double.tryParse(_recurringAmountController.text) ?? 0;
          }
        }

        final newRecurring = RecurringMovement()
          ..title = _titleController.text
          ..type = TransactionType.income
          ..frequency = _selectedFrequency
          ..paymentDays = paymentDays
          ..paymentAmounts = paymentAmounts
          ..isVariableDaily = _isDailyVariable
          ..accumulatedAmount = accumulated
          ..nextPaymentDate = DateTime.now(); 

        // 1. Guardar en Base de Datos
        await recurringDao.addRecurringMovement(newRecurring);

        // ✅ 2. ACTUALIZAR NOTIFICACIONES
        // Obtenemos todos los ingresos activos y reprogramamos sus alarmas
        final allIncomes = await recurringDao.getAllRecurringMovements();
        await NotificationService().scheduleAllNotifications(allIncomes);

      } else {
        // --- GUARDAR INGRESO EXTRA ---
        final transactionDao = ref.read(transactionDaoProvider);

        final newTransaction = FinancialTransaction()
          ..amount = double.parse(_amountController.text)
          ..note = _titleController.text.isEmpty ? "Ingreso Extra" : _titleController.text
          ..date = _selectedDate
          ..type = TransactionType.income
          ..categoryName = "Extra"
          ..categoryIconCode = FontAwesomeIcons.moneyBillWave.codePoint
          ..colorValue = Colors.green.value;

        await transactionDao.addTransaction(newTransaction);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Ingreso guardado exitosamente!")),
        );
      }

    } catch (e) {
      debugPrint("Error al guardar: $e");
    }
  }

  // ===========================================================================
  // FORMULARIOS VISUALES
  // ===========================================================================
  
  Widget _buildEventualForm(ColorScheme colors) {
    return Column(
      children: [
        _buildMoneyInput(_amountController, "Monto Percibido", colors),
        const Gap(15),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: "Descripción (Ej: Venta Zapatos)",
            prefixIcon: const Icon(FontAwesomeIcons.tag, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const Gap(15),
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            decoration: BoxDecoration(
              border: Border.all(color: colors.outline.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(FontAwesomeIcons.calendarDay, color: colors.primary),
                const Gap(10),
                Expanded(
                  child: Text(
                    IsDateToday(_selectedDate) 
                        ? "Hoy (${DateFormat('dd/MM').format(_selectedDate)})"
                        : DateFormat('EEEE d, MMM yyyy', 'es').format(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecurringForm(ColorScheme colors) {
    return Column(
      children: [
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: "Nombre del Ingreso (Ej: Sueldo, Alquiler)",
            prefixIcon: const Icon(FontAwesomeIcons.signature, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const Gap(15),
        DropdownButtonFormField<Frequency>(
          value: _selectedFrequency,
          decoration: InputDecoration(
            labelText: "Frecuencia de Cobro",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(FontAwesomeIcons.clock, size: 18),
          ),
          items: const [
            DropdownMenuItem(value: Frequency.biweekly, child: Text("Quincenal (15 y Último)")),
            DropdownMenuItem(value: Frequency.monthly, child: Text("Mensual")),
            DropdownMenuItem(value: Frequency.weekly, child: Text("Semanal")),
            DropdownMenuItem(value: Frequency.daily, child: Text("Diario")),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _selectedFrequency = val);
          },
        ),
        const Gap(20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.secondaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedFrequency == Frequency.biweekly) _buildBiweeklyForm(colors),
              if (_selectedFrequency == Frequency.monthly) _buildMonthlyForm(colors),
              if (_selectedFrequency == Frequency.weekly) _buildWeeklyForm(colors),
              if (_selectedFrequency == Frequency.daily) _buildDailyForm(colors),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBiweeklyForm(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Configura tus pagos:", style: TextStyle(fontWeight: FontWeight.bold)),
        const Gap(10),
        Row(
          children: [
            Expanded(child: _buildMoneyInput(_amount15Controller, "Día 15", colors)),
            const Gap(10),
            Expanded(child: _buildMoneyInput(_amountLastController, "Día Último", colors)),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthlyForm(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("¿Qué día del mes cobras?", style: TextStyle(fontWeight: FontWeight.bold)),
        const Gap(10),
        DropdownButtonFormField<int>(
          value: _selectedDayOfMonth,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          ),
          items: List.generate(31, (index) => index + 1).map((day) {
            return DropdownMenuItem(value: day, child: Text("Día $day"));
          }).toList(),
          onChanged: (val) => setState(() => _selectedDayOfMonth = val!),
        ),
        const Gap(15),
        _buildMoneyInput(_recurringAmountController, "Monto Mensual", colors),
      ],
    );
  }

  Widget _buildWeeklyForm(ColorScheme colors) {
    const days = ["L", "M", "M", "J", "V", "S", "D"];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("¿Qué día de la semana?", style: TextStyle(fontWeight: FontWeight.bold)),
        const Gap(10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final isSelected = _selectedDayOfWeek == (index + 1);
            return GestureDetector(
              onTap: () => setState(() => _selectedDayOfWeek = index + 1),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: isSelected ? colors.primary : colors.surfaceContainerHighest,
                foregroundColor: isSelected ? colors.onPrimary : colors.onSurface,
                child: Text(days[index], style: const TextStyle(fontSize: 12)),
              ),
            );
          }),
        ),
        const Gap(15),
        _buildMoneyInput(_recurringAmountController, "Monto Semanal", colors),
      ],
    );
  }

  Widget _buildDailyForm(ColorScheme colors) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text("Ingreso Variable"),
          subtitle: const Text("¿El monto cambia cada día?"),
          value: _isDailyVariable,
          onChanged: (val) => setState(() => _isDailyVariable = val),
          contentPadding: EdgeInsets.zero,
        ),
        const Gap(10),
        _buildMoneyInput(
          _recurringAmountController, 
          _isDailyVariable ? "Promedio Diario (Estimado)" : "Monto Fijo Diario", 
          colors
        ),
      ],
    );
  }

  Widget _buildMoneyInput(TextEditingController controller, String label, ColorScheme colors) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        prefixText: "\$ ",
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: colors.surface,
      ),
    );
  }

  bool IsDateToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}