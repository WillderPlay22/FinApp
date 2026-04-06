import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../data/models/category.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/enums.dart';
import '../../../logic/providers/database_providers.dart';
import '../../../logic/providers/currency_providers.dart';
import '../../shared/icon_mapper.dart';
import '../../shared/currency_input_field.dart';
import 'create_category_modal.dart';

class AddExpenseModal extends ConsumerStatefulWidget {
  final Expense? expenseToEdit; 
  final Category? preSelectedCategory; // ✅ NUEVO: Para pre-llenar categoría
  final double? maxAmount; // ✅ NUEVO: Límite para cuando se usa desde ahorros
  final bool isFromSaving; // ✅ NUEVO: Indica si viene de "Usar Ahorro"
  final Function(double amount)? onExpenseSaved; // ✅ NUEVO: Callback al guardar

  const AddExpenseModal({
    super.key, 
    this.expenseToEdit, 
    this.preSelectedCategory,
    this.maxAmount,
    this.isFromSaving = false,
    this.onExpenseSaved,
  });

  @override
  ConsumerState<AddExpenseModal> createState() => _AddExpenseModalState();
}

class _AddExpenseModalState extends ConsumerState<AddExpenseModal> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isFixedExpense = false;
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  Frequency _selectedFrequency = Frequency.monthly;
  bool _isFormValid = false;
  String _selectedCurrency = 'USD';

  @override
  void initState() {
    super.initState();
    if (widget.expenseToEdit != null) {
      final e = widget.expenseToEdit!;
      _amountController.text = e.amount.toString();
      _noteController.text = e.title;
      _isFixedExpense = e.isRecurring;
      _selectedDate = e.date;
      _selectedCategory = e.category.value;
      _selectedFrequency = e.frequency;
      if (e.currencyCode != null) {
        _selectedCurrency = e.currencyCode!;
      }
    } else {
      // Si venimos pre-seleccionados (desde el detalle de categoría)
      if (widget.preSelectedCategory != null) {
        _selectedCategory = widget.preSelectedCategory;
        _isFixedExpense = true; // Asumimos que es fijo si viene de ahí
      }
      if (widget.isFromSaving) {
        _isFixedExpense = false; // Si viene de ahorro, siempre es gasto extra
      }
      // Validar formulario inicial
      _validateForm();
    }
    _amountController.addListener(_validateForm);
    _noteController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _amountController.removeListener(_validateForm);
    _noteController.removeListener(_validateForm);
    super.dispose();
  }

  void _validateForm() {
    final isValid = _amountController.text.isNotEmpty && 
                    _noteController.text.isNotEmpty && 
                    _selectedCategory != null;
    if (isValid != _isFormValid) setState(() => _isFormValid = isValid);
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
      child: SingleChildScrollView(
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
              if (!isEditing && widget.preSelectedCategory == null && !widget.isFromSaving)
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

          // 2. MONTO (con soporte multi-moneda)
          CurrencyInputField(
            controller: _amountController,
            hintText: "0.00",
            maxAmount: widget.maxAmount,
            iconColor: const Color(0xFFE74C3C),
            initialCurrency: _selectedCurrency,
            onCurrencyChanged: (currency) {
              setState(() => _selectedCurrency = currency);
            },
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
              fillColor: colors.surfaceContainerHighest.withAlpha((255 * 0.3).round()),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),

          const Gap(20),

          // 4. SI ES FIJO, MOSTRAMOS SELECTOR DE FRECUENCIA
          if (_isFixedExpense) ...[
            _buildFrequencySelector(colors),
            const Gap(20),
          ],

          // 5. SI NO ES FIJO, MOSTRAMOS FECHA Y CATEGORÍA ABAJO
          if (!_isFixedExpense) ...[
            _buildDatePicker(colors),
            const Gap(20),
            _buildCategorySelector(colors),
            const Gap(20),
          ],

          // BOTÓN GUARDAR
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isFormValid ? _saveExpense : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C), // Coral
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
              icon: const Icon(Icons.delete, color: Color(0xFFE74C3C)),
              label: const Text("Eliminar este Item", style: TextStyle(color: Color(0xFFE74C3C))),
            )
          ],
          const Gap(20),
        ],
      ),
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
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withAlpha((255 * 0.1).round()), blurRadius: 4)] : null,
        ),
        child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.grey, fontSize: 12)),
      ),
    );
  }
  
  Widget _buildFrequencySelector(ColorScheme colors) {
    return Row(
      children: [
        Text("Frecuencia:", style: TextStyle(fontWeight: FontWeight.bold, color: colors.outline)),
        const Gap(12),
        Expanded(
          child: DropdownButtonFormField<Frequency>(
            value: _selectedFrequency,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: colors.surfaceContainerHighest.withAlpha((255 * 0.3).round()),
            ),
            items: const [
              DropdownMenuItem(value: Frequency.weekly, child: Text("Semanal")),
              DropdownMenuItem(value: Frequency.biweekly, child: Text("Quincenal")),
              DropdownMenuItem(value: Frequency.monthly, child: Text("Mensual")),
            ],
            onChanged: (v) => setState(() => _selectedFrequency = v!),
          ),
        ),
      ],
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
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = category);
                      _validateForm();
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
                            getIconFromCode(category.iconCode),
                            color: isSelected ? Colors.white : Colors.grey,
                            size: 20,
                          ),
                        ),
                        const Gap(5),
                        Text(category.name, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
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

  void _saveExpense() async {
    if (_amountController.text.isEmpty || _noteController.text.isEmpty || _selectedCategory == null) return;
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    if (widget.maxAmount != null && amount > widget.maxAmount!) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("El monto excede el saldo disponible en el ahorro.")));
      return;
    }

    // Determinar si multi-moneda esta habilitado
    final isMultiCurrency = ref.read(isMultiCurrencyEnabledProvider);

    // Obtener tasa de cambio actual si multi-moneda está habilitado
    double? currentRate;
    if (isMultiCurrency) {
      final rateData = await ref.read(currentExchangeRateProvider.future);
      currentRate = rateData?.rate;
    }

    ref.read(expenseDaoProvider).saveExpense(
      id: widget.expenseToEdit?.id,
      title: _noteController.text,
      amount: amount,
      date: _selectedDate,
      category: _selectedCategory!,
      isFixed: _isFixedExpense,
      frequency: _isFixedExpense ? _selectedFrequency : Frequency.monthly,
      currencyCode: isMultiCurrency ? _selectedCurrency : null,
      exchangeRate: currentRate,
    );

    if (widget.onExpenseSaved != null) {
      widget.onExpenseSaved!(amount);
    }

    if (!mounted) return;
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

    // Se comprueba que el widget sigue montado ANTES y DESPUÉS de la operación asíncrona.
    if (confirm == true && widget.expenseToEdit != null && mounted) {
      await ref.read(expenseDaoProvider).deleteExpense(widget.expenseToEdit!.id);
      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item eliminado")));
      }
    }
  }
}
