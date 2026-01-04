import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import '../../../data/models/category.dart';
import '../../../data/models/enums.dart';
import '../../../logic/providers/database_providers.dart';

class CreateCategoryModal extends ConsumerStatefulWidget {
  const CreateCategoryModal({super.key});

  @override
  ConsumerState<CreateCategoryModal> createState() => _CreateCategoryModalState();
}

class _CreateCategoryModalState extends ConsumerState<CreateCategoryModal> {
  final _nameController = TextEditingController();
  
  // Selección por defecto
  int _selectedIconCode = FontAwesomeIcons.tag.codePoint;
  Color _selectedColor = Colors.blue;
  Frequency _selectedFrequency = Frequency.monthly;

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Nueva Categoría", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.primary), textAlign: TextAlign.center),
          const Gap(20),

          // 1. NOMBRE
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: "Nombre de la Categoría",
              prefixIcon: Icon(IconData(_selectedIconCode, fontFamily: 'FontAwesomeSolid', fontPackage: 'font_awesome_flutter'), color: _selectedColor),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              filled: true,
              fillColor: colors.surfaceContainerHighest.withOpacity(0.3),
            ),
          ),
          const Gap(20),

          // 2. SELECTOR DE FRECUENCIA
          Row(
            children: [
              const Text("Frecuencia:", style: TextStyle(fontWeight: FontWeight.bold)),
              const Gap(10),
              Expanded(
                child: DropdownButtonFormField<Frequency>(
                  value: _selectedFrequency,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: Frequency.weekly, child: Text("Semanal")),
                    DropdownMenuItem(value: Frequency.biweekly, child: Text("Quincenal")),
                    DropdownMenuItem(value: Frequency.monthly, child: Text("Mensual")),
                    DropdownMenuItem(value: Frequency.yearly, child: Text("Anual")),
                  ], 
                  onChanged: (v) => setState(() => _selectedFrequency = v!),
                ),
              ),
            ],
          ),
          const Gap(5),
          Text("Define cada cuánto se renuevan los gastos fijos de esta categoría.", style: TextStyle(fontSize: 10, color: colors.outline)),

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
                      color: isSelected ? _selectedColor.withOpacity(0.2) : colors.surfaceContainerHighest,
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
            child: const Text("Guardar Categoría", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Gap(20),
        ],
      ),
    );
  }

  void _saveCategory() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Escribe un nombre")));
      return;
    }

    final newCategory = Category(
      name: _nameController.text,
      iconCode: _selectedIconCode,
      colorValue: _selectedColor.value,
      frequency: _selectedFrequency,
      isExpense: true,
    );

    // Guardamos en BD
    ref.read(categoryDaoProvider).addCategory(newCategory);

    Navigator.pop(context); // Cerramos el modal
  }
}