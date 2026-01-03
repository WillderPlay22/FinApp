import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart'; // Para fechas
import '../../../data/models/transaction.dart';
import '../../../logic/providers/database_providers.dart';

class IncomeHistoryList extends ConsumerWidget {
  const IncomeHistoryList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtenemos el DAO para escuchar la base de datos
    final transactionDao = ref.watch(transactionDaoProvider);

    // StreamBuilder mantiene la lista actualizada en vivo
    return StreamBuilder<List<FinancialTransaction>>(
      stream: transactionDao.watchTransactions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final transactions = snapshot.data ?? [];

        // CASO: LISTA VACÍA
        if (transactions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FontAwesomeIcons.ghost, size: 50, color: Colors.grey),
                SizedBox(height: 10),
                Text("No hay ingresos registrados aún"),
              ],
            ),
          );
        }

        // CASO: LISTA CON DATOS
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80), // Espacio para que el botón flotante no tape el último
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            
            // WIDGET MÁGICO PARA BORRAR DESLIZANDO
            return Dismissible(
              key: Key(transaction.id.toString()), // Identificador único
              direction: DismissDirection.endToStart, // Solo deslizar de derecha a izquierda
              
              // Fondo rojo que aparece al deslizar
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              
              // Acción al completar el deslizamiento (Borrar de BD)
              onDismissed: (direction) {
                // 1. Accedemos a la base de datos directamente
                final isarService = ref.read(isarServiceProvider); 
                
                // 2. Ejecutamos el borrado
                isarService.db.then((db) {
                   db.writeTxn(() async {
                     await db.financialTransactions.delete(transaction.id);
                   });
                });
                
                // 3. Avisamos al usuario
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Ingreso eliminado"),
                    duration: Duration(seconds: 2),
                  ),
                );
              },

              // LA TARJETA VISIBLE
              child: Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                    child: Icon(
                      IconData(transaction.categoryIconCode, fontFamily: 'FontAwesomeSolid', fontPackage: 'font_awesome_flutter'),
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    transaction.note,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    // Formato Ej: "20 Ene 2026 - 03:30 PM"
                    DateFormat('dd MMM yyyy - hh:mm a', 'es').format(transaction.date),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: Text(
                    "+ \$${transaction.amount.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}