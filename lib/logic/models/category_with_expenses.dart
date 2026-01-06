import '../../data/models/category.dart';
import '../../data/models/expense.dart';

class CategoryWithExpenses {
  final Category category;
  final List<Expense> expenses;
  final double totalAmount;
  final double totalSpent; // Lo que ya se ha pagado en este ciclo

  CategoryWithExpenses({
    required this.category,
    required this.expenses,
    required this.totalAmount,
    required this.totalSpent,
  });
}