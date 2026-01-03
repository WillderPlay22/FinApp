import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction.dart';
import '../models/recurring_movement.dart';

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
        [FinancialTransactionSchema, RecurringMovementSchema], // Registramos los esquemas
        directory: dir.path,
        inspector: true, // Nos permite ver la BD mientras programamos
      );
    }
    return Future.value(Isar.getInstance());
  }
}