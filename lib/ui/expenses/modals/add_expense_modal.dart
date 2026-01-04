import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../data/models/category.dart';
import '../../../data/models/expense.dart';
import '../../../logic/providers/database_providers.dart';
// 1. IMPORTAMOS EL MODAL DE CREAR CATEGORÍA
import 'create_category_modal.dart';

class AddExpenseModal extends ConsumerStatefulWidget {
  const AddExpenseModal({super.key});

  @override
  ConsumerState<AddExpenseModal> createState() => _AddExpenseModalState();
}

class _AddExpenseModalState extends ConsumerState<AddExpenseModal> {
  // Controladores de texto
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  // Variables de Estado
  bool _isFixedExpense = false; // ¿Es gasto fijo?
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final categoryDao = ref.watch(categoryDaoProvider);

    return Container(
      padding: EdgeInsets.only(
        top: 20, 
        left: 20, 
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20 // Para el teclado
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. TÍTULO Y TIPO DE GASTO
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Registrar Gasto", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.primary)),
              
              // Switch Personalizado (Extra vs Fijo)
              Container(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
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

          // 2. INPUT DE MONTO (GRANDE)
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

          // 3. INPUT DE NOTA / TÍTULO
          TextField(
            controller: _noteController,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: _isFixedExpense ? "Ej: Alquiler, Netflix..." : "Ej: Tacos, Uber...",
              filled: true,
              fillColor: colors.surfaceContainerHighest.withOpacity(0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),

          const Gap(20),

          // 4. SELECTOR DE FECHA (Solo si es Gasto Extra)
          if (!_isFixedExpense) 
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(FontAwesomeIcons.calendarDay, size: 18, color: Colors.grey),
                    const Gap(10),
                    Text(
                      DateFormat('dd MMM yyyy', 'es').format(_selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    const Text("Cambiar", style: TextStyle(color: Colors.blue, fontSize: 12)),
                  ],
                ),
              ),
            ),
            
          const Gap(20),

          // 5. GRID DE CATEGORÍAS
          Text("Selecciona Categoría:", style: TextStyle(fontWeight: FontWeight.bold, color: colors.outline)),
          const Gap(10),
          
          SizedBox(
            height: 100, // Altura fija para el scroll horizontal
            child: StreamBuilder<List<Category>>(
              stream: categoryDao.watchExpenseCategories(),
              builder: (context, snapshot) {
                final categories = snapshot.data ?? [];
                
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length + 1, // +1 para el botón de "Nueva"
                  separatorBuilder: (c, i) => const Gap(12),
                  itemBuilder: (context, index) {
                    // Botón "Nueva Categoría" (El último)
                    if (index == categories.length) {
                      return _buildAddCategoryButton(colors);
                    }

                    final category = categories[index];
                    final isSelected = _selectedCategory?.id == category.id;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
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
                          Text(
                            category.name, 
                            style: TextStyle(
                              fontSize: 10, 
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                            )
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const Gap(20),

          // 6. BOTÓN GUARDAR
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
              child: const Text("Registrar Gasto", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const Gap(20),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

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
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : Colors.grey,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // 2. LÓGICA CONECTADA AL BOTÓN "NUEVA"
  Widget _buildAddCategoryButton(ColorScheme colors) {
    return GestureDetector(
      onTap: () {
        // ABRIR MODAL DE CREAR CATEGORÍA
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) => const CreateCategoryModal(),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: colors.outline, style: BorderStyle.solid),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add, color: colors.outline, size: 20),
          ),
          const Gap(5),
          const Text("Nueva", style: TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  // --- LÓGICA ---

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveExpense() {
    // 1. Validaciones
    if (_amountController.text.isEmpty) return;
    if (_noteController.text.isEmpty) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Por favor selecciona una categoría")));
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    // 2. Crear Objeto
    final newExpense = Expense(
      title: _noteController.text,
      amount: amount,
      date: _selectedDate,
      isRecurring: _isFixedExpense, // TRUE si es fijo, FALSE si es extra
    );

    // 3. Guardar en BD
    ref.read(expenseDaoProvider).addExpense(newExpense, _selectedCategory!);

    // 4. Cerrar
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gasto registrado exitosamente")));
  }
}