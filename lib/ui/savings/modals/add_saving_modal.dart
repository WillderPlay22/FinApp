import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:finapp/data/models/saving.dart';
import 'package:finapp/data/models/enums.dart';
import 'package:finapp/logic/providers/database_providers.dart';

class AddSavingModal extends ConsumerStatefulWidget {
  const AddSavingModal({super.key});

  @override
  ConsumerState<AddSavingModal> createState() => _AddSavingModalState();
}

class _AddSavingModalState extends ConsumerState<AddSavingModal> {
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _valueController = TextEditingController(); // Sirve para monto fijo o porcentaje

  SavingType _selectedType = SavingType.goal;
  SavingMethod _selectedMethod = SavingMethod.fixed;
  int _selectedColor = 0xFFE91E63;
  int _selectedIcon = FontAwesomeIcons.piggyBank.codePoint;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.only(
        top: 20, left: 20, right: 20,
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
            const Text("Nuevo Plan de Ahorro", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const Gap(20),

            // NOMBRE
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Nombre (Ej: Auto Nuevo, Emergencias)",
                prefixIcon: const Icon(Icons.label_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const Gap(15),

            // TIPO DE AHORRO (Meta vs Fondo)
            Row(
              children: [
                Expanded(
                  child: _buildTypeSelector(
                    "Meta", "Con objetivo", FontAwesomeIcons.flagCheckered, SavingType.goal, colors
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: _buildTypeSelector(
                    "Fondo", "Indefinido", FontAwesomeIcons.infinity, SavingType.fund, colors
                  ),
                ),
              ],
            ),
            const Gap(15),

            // MONTO META (Solo si es Meta)
            if (_selectedType == SavingType.goal) ...[
              TextField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Monto Objetivo",
                  prefixIcon: const Icon(Icons.track_changes),
                  prefixText: "\$ ",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const Gap(15),
            ],

            const Divider(),
            const Text("Método de Ahorro Mensual", style: TextStyle(fontWeight: FontWeight.bold)),
            const Gap(10),

            // MÉTODO (Fijo vs Porcentaje)
            DropdownButtonFormField<SavingMethod>(
              value: _selectedMethod,
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: const [
                DropdownMenuItem(value: SavingMethod.fixed, child: Text("Monto Fijo Mensual")),
                DropdownMenuItem(value: SavingMethod.percentage, child: Text("Porcentaje del Remanente")),
              ],
              onChanged: (val) => setState(() => _selectedMethod = val!),
            ),
            const Gap(10),

            TextField(
              controller: _valueController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _selectedMethod == SavingMethod.fixed ? "Monto a Ahorrar" : "Porcentaje a Ahorrar",
                prefixText: _selectedMethod == SavingMethod.fixed ? "\$ " : "% ",
                suffixText: _selectedMethod == SavingMethod.percentage ? "%" : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                helperText: _selectedMethod == SavingMethod.percentage 
                    ? "Se calculará sobre (Ingresos - Gastos) proyectados." 
                    : null,
              ),
            ),
            const Gap(20),

            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("CREAR AHORRO"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector(String title, String sub, IconData icon, SavingType type, ColorScheme colors) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pinkAccent.withAlpha(30) : colors.surfaceContainer,
          border: Border.all(color: isSelected ? Colors.pinkAccent : Colors.transparent, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.pinkAccent : colors.outline),
            const Gap(5),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.pinkAccent : colors.onSurface)),
            Text(sub, style: TextStyle(fontSize: 10, color: colors.outline)),
          ],
        ),
      ),
    );
  }

  void _save() async {
    if (_nameController.text.isEmpty) return;
    if (_selectedType == SavingType.goal && _targetController.text.isEmpty) return;
    if (_valueController.text.isEmpty) return;

    final dao = ref.read(savingsDaoProvider);
    final val = double.tryParse(_valueController.text) ?? 0.0;

    final newSaving = Saving()
      ..name = _nameController.text
      ..type = _selectedType
      ..targetAmount = _selectedType == SavingType.goal ? double.tryParse(_targetController.text) : null
      ..method = _selectedMethod
      ..fixedAmount = _selectedMethod == SavingMethod.fixed ? val : null
      ..percentage = _selectedMethod == SavingMethod.percentage ? val : null
      ..colorValue = _selectedColor
      ..iconCode = _selectedIcon;

    await dao.saveSaving(newSaving);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Plan de ahorro creado")),
      );
    }
  }
}