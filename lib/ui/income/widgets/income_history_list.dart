import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../../data/models/transaction.dart';
import '../../../logic/providers/database_providers.dart';

class IncomeHistoryList extends ConsumerWidget {
  const IncomeHistoryList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionDao = ref.watch(transactionDaoProvider);

    // ✅ Usamos el stream filtrado (Solo Ingresos)
    return StreamBuilder<List<FinancialTransaction>>(
      stream: transactionDao.watchIncomeTransactions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final transactions = snapshot.data ?? [];

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

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            
            // ✅ WIDGET PARA BORRAR DESLIZANDO
            return Dismissible(
              key: Key(transaction.id.toString()),
              direction: DismissDirection.endToStart, // Deslizar izquierda
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("¿Borrar ingreso?"),
                    content: const Text("Esta acción no se puede deshacer."),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Borrar", style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
              },
              onDismissed: (direction) {
                // Borramos usando el DAO
                transactionDao.deleteTransaction(transaction.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Ingreso eliminado"), duration: Duration(seconds: 2)),
                );
              },
              child: Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.1), // Corrección opacidad
                    child: Icon(
                      IconData(transaction.categoryIconCode, fontFamily: 'FontAwesomeSolid', fontPackage: 'font_awesome_flutter'),
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  title: Text(transaction.note, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    DateFormat('dd MMM yyyy - hh:mm a', 'es').format(transaction.date),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: Text(
                    "+ \$${transaction.amount.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 16),
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