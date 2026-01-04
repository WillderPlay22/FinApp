import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
// Modelos de Ingresos (Antiguos)
import '../models/transaction.dart';
import '../models/recurring_movement.dart';
// Modelos de Gastos (NUEVOS - Faltaban aquí)
import '../models/category.dart';
import '../models/expense.dart';

class IsarService {
  late Future<Isar> db;

  IsarService() {
    db = openDB();
  }

  Future<Isar> openDB() async {
    // Si la BD ya está abierta, la usamos
    if (Isar.instanceNames.isEmpty) {
      // Buscamos la carpeta segura donde guardar datos en el celular
      final dir = await getApplicationDocumentsDirectory();
      
      return await Isar.open(
        [
          FinancialTransactionSchema, 
          RecurringMovementSchema,
          // AGREGAMOS LOS NUEVOS ESQUEMAS AQUÍ:
          CategorySchema,
          ExpenseSchema,
        ], 
        directory: dir.path,
        inspector: true, // Nos permite ver la BD mientras programamos
      );
    }
    return Future.value(Isar.getInstance());
  }
}