import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart'; // Para formatear fechas
import '../../../data/models/expense.dart';
import '../../../logic/providers/database_providers.dart';

class ExpenseHistoryList extends ConsumerWidget {
  const ExpenseHistoryList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseDao = ref.watch(expenseDaoProvider);
    final colors = Theme.of(context).colorScheme;

    return StreamBuilder<List<Expense>>(
      stream: expenseDao.watchAllExpenses(), // Escuchamos TODOS los gastos
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Error al cargar historial"));
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FontAwesomeIcons.clock, size: 50, color: colors.outlineVariant),
                const Gap(10),
                const Text("Tu historial está vacío."),
              ],
            ),
          );
        }

        final expenses = snapshot.data!;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: expenses.length,
          separatorBuilder: (c, i) => Divider(color: colors.outlineVariant.withOpacity(0.2)),
          itemBuilder: (context, index) {
            final expense = expenses[index];
            return _ExpenseItem(expense: expense, dao: expenseDao);
          },
        );
      },
    );
  }
}

class _ExpenseItem extends StatelessWidget {
  final Expense expense;
  final dynamic dao; // Recibimos el DAO para poder borrar

  const _ExpenseItem({required this.expense, required this.dao});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final category = expense.category.value; // Obtenemos la categoría vinculada

    // Si por alguna razón se borró la categoría, usamos valores por defecto
    final iconCode = category?.iconCode ?? FontAwesomeIcons.circleQuestion.codePoint;
    final colorValue = category?.colorValue ?? Colors.grey.value;
    
    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        // Preguntar antes de borrar
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("¿Borrar gasto?"),
            content: Text("Vas a eliminar '${expense.title}' de \$${expense.amount}."),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Cancelar")),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Borrar", style: TextStyle(color: Colors.red))),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        // Ejecutar borrado
        dao.deleteExpense(expense.id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gasto eliminado")));
      },
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 45, height: 45,
          decoration: BoxDecoration(
            color: Color(colorValue).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            IconData(iconCode, fontFamily: 'FontAwesomeSolid', fontPackage: 'font_awesome_flutter'),
            color: Color(colorValue),
            size: 20,
          ),
        ),
        title: Text(
          expense.title, 
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        subtitle: Row(
          children: [
            // Fecha bonita (ej: 02 Ene)
            Text(DateFormat('dd MMM', 'es').format(expense.date), style: TextStyle(fontSize: 12, color: colors.outline)),
            const Gap(8),
            // Badge si es Fijo
            if (expense.isRecurring)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(4)
                ),
                child: Text("Fijo", style: TextStyle(fontSize: 9, color: colors.onPrimaryContainer)),
              ),
          ],
        ),
        trailing: Text(
          "- \$ ${expense.amount.toStringAsFixed(2)}",
          style: const TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 16, 
            color: Colors.red
          ),
        ),
      ),
    );
  }
}