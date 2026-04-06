import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:isar/isar.dart';
import '../../../data/models/category.dart';
import '../../../logic/providers/database_providers.dart';
import '../../shared/icon_mapper.dart'; // ✅ Esta ruta ya es correcta

class CreateCategoryModal extends ConsumerStatefulWidget {
  // ✅ 1. AÑADIMOS EL PARÁMETRO PARA RECIBIR LA CATEGORÍA A EDITAR
  final Category? categoryToEdit;

  const CreateCategoryModal({super.key, this.categoryToEdit});

  @override
  ConsumerState<CreateCategoryModal> createState() => _CreateCategoryModalState();
}

class _CreateCategoryModalState extends ConsumerState<CreateCategoryModal> {
  final _nameController = TextEditingController();

  // ✅ 2. UN GETTER PARA SABER FÁCILMENTE SI ESTAMOS EDITANDO
  bool get isEditing => widget.categoryToEdit != null;

  final _budgetLimitController = TextEditingController();

  // Seleccion por defecto
  int _selectedIconCode = FontAwesomeIcons.tag.codePoint;
  Color _selectedColor = Colors.blue;
  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final category = widget.categoryToEdit!;
      _nameController.text = category.name;
      _selectedIconCode = category.iconCode;
      _selectedColor = Color(category.colorValue);
      if (category.budgetLimit != null) {
        _budgetLimitController.text = category.budgetLimit!.toStringAsFixed(0);
      }
    }
  }

  // LISTA DE ICONOS DISPONIBLES
  final List<IconData> _icons = [
    FontAwesomeIcons.tag, FontAwesomeIcons.burger, FontAwesomeIcons.bus, 
    FontAwesomeIcons.house, FontAwesomeIcons.bolt, FontAwesomeIcons.heartPulse,
    FontAwesomeIcons.bagShopping, FontAwesomeIcons.gamepad, FontAwesomeIcons.graduationCap,
    FontAwesomeIcons.paw, FontAwesomeIcons.plane, FontAwesomeIcons.dumbbell,
    FontAwesomeIcons.shirt, FontAwesomeIcons.gift, FontAwesomeIcons.wrench,
    FontAwesomeIcons.car, FontAwesomeIcons.wifi, FontAwesomeIcons.mobile,
    FontAwesomeIcons.baby, FontAwesomeIcons.book,
  ];

  // LISTA DE COLORES DISPONIBLES
  final List<Color> _colors = [
    Colors.blue, Colors.red, Colors.green, Colors.orange, 
    Colors.purple, Colors.teal, Colors.pink, Colors.brown,
    Colors.indigo, Colors.amber, Colors.cyan, Colors.deepOrange,
    Colors.lime, Colors.blueGrey,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.only(
        top: 20, left: 20, right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20
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
            // ✅ 4. CAMBIAMOS EL TÍTULO DINÁMICAMENTE
            Text(isEditing ? "Editar Categoría" : "Nueva Categoría", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.primary), textAlign: TextAlign.center),
            const Gap(20),

          // 1. NOMBRE
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: "Nombre de la Categoría",
              prefixIcon: Icon(getIconFromCode(_selectedIconCode), color: _selectedColor),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              filled: true,
              fillColor: colors.surfaceContainerHighest.withAlpha((255 * 0.3).round()),
            ),
          ),
            const Gap(20),

            // LIMITE DE PRESUPUESTO (OPCIONAL)
            TextField(
              controller: _budgetLimitController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Límite de presupuesto (opcional)",
                hintText: "Ej: 500000",
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: colors.surfaceContainerHighest.withAlpha((255 * 0.3).round()),
              ),
            ),
            const Gap(5),
            Text("Si defines un límite, verás un indicador cuando te acerques o lo excedas.", style: TextStyle(fontSize: 10, color: colors.outline)),

            const Gap(20),

            // 3. SELECTOR DE COLORES
            const Text("Color:", style: TextStyle(fontWeight: FontWeight.bold)),
            const Gap(10),
            SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _colors.length,
              separatorBuilder: (c, i) => const Gap(10),
              itemBuilder: (context, index) {
                final color = _colors[index];
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: colors.onSurface, width: 3) : null,
                    ),
                    child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                  ),
                );
              },
            ),
            ),

            const Gap(20),

            // 4. SELECTOR DE ICONOS (GRID)
            const Text("Icono:", style: TextStyle(fontWeight: FontWeight.bold)),
            const Gap(10),
            SizedBox(
            height: 150, // Altura limitada para el grid
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6, 
                mainAxisSpacing: 10, 
                crossAxisSpacing: 10
              ),
              itemCount: _icons.length,
              itemBuilder: (context, index) {
                final icon = _icons[index];
                final isSelected = _selectedIconCode == icon.codePoint;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIconCode = icon.codePoint),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? _selectedColor.withAlpha((255 * 0.2).round()) : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected ? Border.all(color: _selectedColor, width: 2) : null,
                    ),
                    child: Icon(icon, color: isSelected ? _selectedColor : colors.outline, size: 20),
                  ),
                );
              },
            ),
            ),

            const Gap(20),

            // 5. BOTÓN GUARDAR
            ElevatedButton(
              onPressed: _saveCategory,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              // ✅ 5. CAMBIAMOS EL TEXTO DEL BOTÓN
              child: Text(isEditing ? "Guardar Cambios" : "Guardar Categoría", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const Gap(20),
          ],
        ),
      ),
    );
  }

  void _saveCategory() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Escribe un nombre")));
      return;
    }

    final budgetText = _budgetLimitController.text.trim();
    final budgetLimit = budgetText.isNotEmpty ? double.tryParse(budgetText) : null;

    final category = Category(
      name: _nameController.text,
      iconCode: _selectedIconCode,
      // ignore: deprecated_member_use
      colorValue: _selectedColor.value,
      isExpense: true,
      budgetLimit: budgetLimit,
    )..id = widget.categoryToEdit?.id ?? Isar.autoIncrement;

    // Guardamos en BD
    ref.read(categoryDaoProvider).addCategory(category);

    Navigator.pop(context); // Cerramos el modal
  }
}