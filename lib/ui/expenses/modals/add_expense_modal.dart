import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../data/models/category.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/enums.dart'; 
import '../../../logic/providers/database_providers.dart';
import 'create_category_modal.dart';

class AddExpenseModal extends ConsumerStatefulWidget {
  final Expense? expenseToEdit; 
  final Category? preSelectedCategory; // ✅ NUEVO: Para pre-llenar categoría

  const AddExpenseModal({super.key, this.expenseToEdit, this.preSelectedCategory});

  @override
  ConsumerState<AddExpenseModal> createState() => _AddExpenseModalState();
}

class _AddExpenseModalState extends ConsumerState<AddExpenseModal> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  bool _isFixedExpense = false;
  Frequency _selectedFrequency = Frequency.monthly;
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    if (widget.expenseToEdit != null) {
      final e = widget.expenseToEdit!;
      _amountController.text = e.amount.toString();
      _noteController.text = e.title;
      _isFixedExpense = e.isRecurring;
      _selectedFrequency = e.frequency;
      _selectedDate = e.date;
      _selectedCategory = e.category.value;
    } else {
      // Si venimos pre-seleccionados (desde el detalle de categoría)
      if (widget.preSelectedCategory != null) {
        _selectedCategory = widget.preSelectedCategory;
        _isFixedExpense = true; // Asumimos que es fijo si viene de ahí
        _selectedFrequency = _selectedCategory!.frequency ?? Frequency.monthly;
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isEditing = widget.expenseToEdit != null;

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
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isEditing ? "Editar Item" : "Registrar Gasto", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.primary)),
              // Si ya venimos con categoría preseleccionada, bloqueamos el switch
              if (!isEditing && widget.preSelectedCategory == null)
                Container(
                  decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      _buildTypeButton("Extra", false),
                      _buildTypeButton("Fijo", true),
                    ],
                  ),
                )
            ],
          ),
          
          const Gap(20),

          // 1. SI ES FIJO, LA CATEGORÍA VA PRIMERO
          if (_isFixedExpense) ...[
             _buildCategorySelector(colors),
             const Gap(20),
          ],

          // 2. MONTO
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.red),
            decoration: InputDecoration(
              hintText: "0.00",
              prefixIcon: const Icon(Icons.attach_money, color: Colors.red),
              border: InputBorder.none,
              hintStyle: TextStyle(color: colors.outline.withOpacity(0.3)),
            ),
          ),

          const Gap(10),

          // 3. NOMBRE DEL ITEM (Sub-gasto)
          TextField(
            controller: _noteController,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              // Cambiamos el placeholder para que entienda que es un item
              hintText: _isFixedExpense ? "Nombre del Item (Ej: Carne, Gas...)" : "Ej: Desayuno, Uber...",
              filled: true,
              fillColor: colors.surfaceContainerHighest.withOpacity(0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),

          const Gap(20),

          // 4. SI NO ES FIJO, MOSTRAMOS FECHA Y CATEGORÍA ABAJO
          if (!_isFixedExpense) ...[
            _buildDatePicker(colors),
            const Gap(20),
            _buildCategorySelector(colors),
            const Gap(20),
          ],
          
          // NOTA: Si es fijo, ocultamos fecha y frecuencia, ya que las hereda de la Categoría.

          // BOTÓN GUARDAR
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveExpense,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: Text(isEditing ? "Guardar Cambios" : "Agregar Item", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          
          // ... (Botón eliminar igual que antes)
           if (isEditing) ...[
            const Gap(10),
            TextButton.icon(
              onPressed: _deleteExpense,
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text("Eliminar este Item", style: TextStyle(color: Colors.red)),
            )
          ],
          const Gap(20),
        ],
      ),
    );
  }

  // ... (Widgets auxiliares: _buildTypeButton, _buildDatePicker igual que antes)
  Widget _buildTypeButton(String text, bool isFixed) {
    final isSelected = _isFixedExpense == isFixed;
    return GestureDetector(
      onTap: () => setState(() => _isFixedExpense = isFixed),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : null,
        ),
        child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.grey, fontSize: 12)),
      ),
    );
  }
  
   Widget _buildDatePicker(ColorScheme colors) {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(border: Border.all(color: colors.outlineVariant), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(FontAwesomeIcons.calendarDay, size: 18, color: Colors.grey),
            const Gap(10),
            Text(DateFormat('dd MMM yyyy', 'es').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            const Text("Cambiar", style: TextStyle(color: Colors.blue, fontSize: 12)),
          ],
        ),
      ),
    );
  }
  
  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030), locale: const Locale('es', 'ES'));
    if (picked != null) setState(() => _selectedDate = picked);
  }


  Widget _buildCategorySelector(ColorScheme colors) {
    final categoryDao = ref.watch(categoryDaoProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_isFixedExpense ? "Pertenece a la Categoría:" : "Selecciona Categoría:", style: TextStyle(fontWeight: FontWeight.bold, color: colors.outline)),
        const Gap(10),
        SizedBox(
          height: 100,
          child: StreamBuilder<List<Category>>(
            stream: categoryDao.watchExpenseCategories(),
            builder: (context, snapshot) {
              final categories = snapshot.data ?? [];
              
              // SI ES GASTO FIJO, FILTRAMOS SOLO CATEGORÍAS CON FRECUENCIA ASIGNADA (Opcional, pero buena práctica)
              // final filtered = _isFixedExpense ? categories.where((c) => c.frequency != null).toList() : categories;
              // Usamos todas por ahora para evitar errores si el usuario no ha puesto frecuencia
              
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length + 1,
                separatorBuilder: (c, i) => const Gap(12),
                itemBuilder: (context, index) {
                  if (index == categories.length) return _buildAddCategoryButton(colors);
                  final category = categories[index];
                  final isSelected = _selectedCategory?.id == category.id;
                  
                  // Si estamos en modo Fijo, mostrar la frecuencia en la tarjeta
                  final showFreq = _isFixedExpense && category.frequency != null;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                        // Si es fijo, el gasto hereda la frecuencia de la categoría
                        if (_isFixedExpense && category.frequency != null) {
                          _selectedFrequency = category.frequency!;
                        }
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected ? Color(category.colorValue) : colors.surfaceContainerHighest,
                            shape: BoxShape.circle,
                            border: isSelected ? Border.all(color: colors.onSurface, width: 2) : null,
                          ),
                          child: Icon(
                            IconData(category.iconCode, fontFamily: 'FontAwesomeSolid', fontPackage: 'font_awesome_flutter'),
                            color: isSelected ? Colors.white : Colors.grey,
                            size: 20,
                          ),
                        ),
                        const Gap(5),
                        Text(category.name, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        if (showFreq) 
                          Text(category.frequency.toString().split('.').last, style: const TextStyle(fontSize: 8, color: Colors.blueGrey)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddCategoryButton(ColorScheme colors) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true, builder: (context) => const CreateCategoryModal());
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(border: Border.all(color: colors.outline), shape: BoxShape.circle),
            child: Icon(Icons.add, color: colors.outline, size: 20),
          ),
          const Gap(5),
          const Text("Nueva", style: TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  void _saveExpense() {
    if (_amountController.text.isEmpty || _noteController.text.isEmpty || _selectedCategory == null) return;
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    ref.read(expenseDaoProvider).saveExpense(
      id: widget.expenseToEdit?.id,
      title: _noteController.text,
      amount: amount,
      date: _selectedDate,
      category: _selectedCategory!,
      isFixed: _isFixedExpense,
      // Si es fijo, usamos la frecuencia de la categoría, si no, mensual por defecto
      frequency: _isFixedExpense ? (_selectedCategory!.frequency ?? Frequency.monthly) : Frequency.monthly,
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Guardado correctamente")));
  }
  
   void _deleteExpense() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Eliminar gasto?"),
        content: const Text("Se borrará este item y su historial."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Eliminar", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && widget.expenseToEdit != null) {
      await ref.read(expenseDaoProvider).deleteExpense(widget.expenseToEdit!.id);
      if (context.mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item eliminado")));
      }
    }
  }
}