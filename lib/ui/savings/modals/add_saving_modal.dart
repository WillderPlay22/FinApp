import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:finapp/data/models/saving.dart';
import 'package:finapp/data/models/enums.dart';
import 'package:finapp/logic/providers/database_providers.dart';
import 'package:finapp/logic/providers/decimal_separator_provider.dart';
import '../../shared/amount_input_formatter.dart';
import '../../../config/theme/app_colors.dart';

class AddSavingModal extends ConsumerStatefulWidget {
  const AddSavingModal({super.key});

  @override
  ConsumerState<AddSavingModal> createState() => _AddSavingModalState();
}

class _AddSavingModalState extends ConsumerState<AddSavingModal> {
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _valueController = TextEditingController();

  SavingType _selectedType = SavingType.goal;
  SavingMethod _selectedMethod = SavingMethod.fixed;
  final int _selectedColor = 0xFF9B59B6;
  final int _selectedIcon = FontAwesomeIcons.piggyBank.codePoint;
  bool _isFormValid = false;
  String _decimalSep = '.';

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _targetController.addListener(_validateForm);
    _valueController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameController.removeListener(_validateForm);
    _targetController.removeListener(_validateForm);
    _valueController.removeListener(_validateForm);
    _nameController.dispose();
    _targetController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _validateForm() {
    bool isValid =
        _nameController.text.isNotEmpty && _valueController.text.isNotEmpty;
    if (_selectedType == SavingType.goal) {
      isValid = isValid && _targetController.text.isNotEmpty;
    }
    if (isValid != _isFormValid) setState(() => _isFormValid = isValid);
  }

  InputDecoration _inputDecoration(ColorScheme colors, String label,
      {String? prefix, String? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixText: prefix,
      suffixText: suffix,
      filled: true,
      fillColor: colors.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _decimalSep = ref.watch(decimalSeparatorProvider);
    final colors = Theme.of(context).colorScheme;
    final appColors = AppColors.of(context);

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // — Drag handle —
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: appColors.textSecondary.withAlpha(60),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Gap(16),
            Text(
              'Nuevo Plan de Ahorro',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: appColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(20),

            // — Nombre —
            TextField(
              controller: _nameController,
              decoration: _inputDecoration(colors,
                  'Nombre (Ej: Auto Nuevo, Emergencias)'),
            ),
            const Gap(16),

            // — Tipo de ahorro —
            Row(
              children: [
                Expanded(
                  child: _buildTypeSelector(
                    'Meta',
                    'Con objetivo',
                    FontAwesomeIcons.flagCheckered,
                    SavingType.goal,
                    appColors,
                    colors,
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: _buildTypeSelector(
                    'Fondo',
                    'Indefinido',
                    FontAwesomeIcons.infinity,
                    SavingType.fund,
                    appColors,
                    colors,
                  ),
                ),
              ],
            ),
            const Gap(16),

            // — Monto meta —
            if (_selectedType == SavingType.goal) ...[
              TextField(
                controller: _targetController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  AmountInputFormatter(decimalSeparator: _decimalSep)
                ],
                decoration: _inputDecoration(colors, 'Monto Objetivo',
                    prefix: '\$ '),
              ),
              const Gap(16),
            ],

            Divider(color: appColors.textSecondary.withAlpha(40)),
            const Gap(8),
            Text(
              'Método de Ahorro Mensual',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: appColors.textPrimary,
                  fontSize: 13),
            ),
            const Gap(12),

            // — Método —
            DropdownButtonFormField<SavingMethod>(
              initialValue: _selectedMethod,
              decoration: _inputDecoration(colors, 'Método'),
              dropdownColor: colors.surfaceContainerHighest,
              items: const [
                DropdownMenuItem(
                    value: SavingMethod.fixed,
                    child: Text('Monto Fijo Mensual')),
                DropdownMenuItem(
                    value: SavingMethod.percentage,
                    child: Text('Porcentaje del Remanente')),
              ],
              onChanged: (val) {
                setState(() => _selectedMethod = val!);
                _validateForm();
              },
            ),
            const Gap(12),

            // — Valor —
            TextField(
              controller: _valueController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: _selectedMethod == SavingMethod.fixed
                  ? [AmountInputFormatter(decimalSeparator: _decimalSep)]
                  : [],
              decoration: _inputDecoration(
                colors,
                _selectedMethod == SavingMethod.fixed
                    ? 'Monto a Ahorrar'
                    : 'Porcentaje a Ahorrar',
                prefix: _selectedMethod == SavingMethod.fixed ? '\$ ' : null,
                suffix:
                    _selectedMethod == SavingMethod.percentage ? '%' : null,
              ).copyWith(
                helperText: _selectedMethod == SavingMethod.percentage
                    ? 'Se calculará sobre (Ingresos - Gastos) proyectados.'
                    : null,
              ),
            ),
            const Gap(24),

            // — Botón —
            FilledButton(
              onPressed: _isFormValid ? _save : null,
              style: FilledButton.styleFrom(
                backgroundColor: appColors.savingsColor,
                disabledBackgroundColor:
                    appColors.savingsColor.withAlpha(60),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'CREAR AHORRO',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector(
    String title,
    String sub,
    IconData icon,
    SavingType type,
    AppColors appColors,
    ColorScheme colors,
  ) {
    final isSelected = _selectedType == type;
    final accentColor = appColors.savingsColor;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedType = type);
        _validateForm();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withAlpha(25)
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            FaIcon(icon,
                color: isSelected ? accentColor : appColors.textSecondary,
                size: 18),
            const Gap(6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? accentColor : appColors.textPrimary,
                fontSize: 13,
              ),
            ),
            Text(
              sub,
              style: TextStyle(
                  fontSize: 10, color: appColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  void _save() async {
    if (_nameController.text.isEmpty) return;
    if (_selectedType == SavingType.goal && _targetController.text.isEmpty) {
      return;
    }
    if (_valueController.text.isEmpty) return;

    final dao = ref.read(savingsDaoProvider);
    final val = _selectedMethod == SavingMethod.fixed
        ? parseAmount(_valueController.text, _decimalSep)
        : (double.tryParse(_valueController.text) ?? 0.0);

    final newSaving = Saving()
      ..name = _nameController.text
      ..type = _selectedType
      ..targetAmount = _selectedType == SavingType.goal
          ? parseAmount(_targetController.text, _decimalSep)
          : null
      ..method = _selectedMethod
      ..fixedAmount = _selectedMethod == SavingMethod.fixed ? val : null
      ..percentage = _selectedMethod == SavingMethod.percentage ? val : null
      ..colorValue = _selectedColor
      ..iconCode = _selectedIcon;

    await dao.saveSaving(newSaving);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan de ahorro creado')),
      );
    }
  }
}
