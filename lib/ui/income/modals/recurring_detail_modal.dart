import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../data/models/recurring_movement.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/transaction.dart';
import '../../../data/daos/transaction_dao.dart'; 
import '../../../logic/providers/time_provider.dart';
import '../../../logic/providers/database_providers.dart'; 

class RecurringDetailModal extends ConsumerStatefulWidget {
  final RecurringMovement movement;

  const RecurringDetailModal({super.key, required this.movement});

  @override
  ConsumerState<RecurringDetailModal> createState() => _RecurringDetailModalState();
}

class _RecurringDetailModalState extends ConsumerState<RecurringDetailModal> {
  
  void _refresh() {
    setState(() {});
  }

  // Traducción limpia
  final Map<Frequency, String> frequencyNames = {
    Frequency.daily: "Diario",
    Frequency.weekly: "Semanal",
    Frequency.biweekly: "Quincenal",
    Frequency.monthly: "Mensual",
    Frequency.yearly: "Anual",
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    final currentDate = ref.watch(nowProvider);
    final transactionDao = ref.watch(transactionDaoProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                const SizedBox(width: 48), 
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(FontAwesomeIcons.fileContract, size: 32, color: Colors.indigo),
                ),
                IconButton(
                  onPressed: () => _showEditDialog(context), 
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  tooltip: "Editar",
                ),
              ],
            ),
            const Gap(16),
            
            // TÍTULO LIMPIO (Sin "Ingreso Recurrente")
            Text(
              frequencyNames[widget.movement.frequency] ?? "Recurrente", 
              textAlign: TextAlign.center, 
              style: textStyles.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
            ),
            Text(
              widget.movement.title, 
              textAlign: TextAlign.center, 
              style: TextStyle(color: colors.outline, fontSize: 14)
            ),
            
            const Gap(24), const Divider(), const Gap(16),

            // CICLO
            Row(
              children: [
                Icon(FontAwesomeIcons.calendarCheck, size: 16, color: colors.primary),
                const Gap(8),
                Text(
                  "Ciclo: ${DateFormat('MMMM yyyy', 'es').format(currentDate).toUpperCase()}",
                  style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary, letterSpacing: 1),
                ),
              ],
            ),
            const Gap(15),

            // CONTROLES DE PAGO SEGÚN FRECUENCIA
            if (widget.movement.frequency == Frequency.daily)
              _buildDailyControls(context, currentDate, transactionDao)
            else if (widget.movement.frequency == Frequency.weekly)
              _buildWeeklyControls(context, currentDate, transactionDao)
            else if (widget.movement.frequency == Frequency.biweekly)
              _buildBiweeklyControls(context, currentDate, transactionDao)
            else if (widget.movement.frequency == Frequency.monthly)
              _buildMonthlyControls(context, currentDate, transactionDao)
            else
              const Text("Frecuencia no soportada aún."),

            const Gap(30),
          ],
        ),
      ),
    );
  }

  // --- 1. CONTROL DIARIO ---
  Widget _buildDailyControls(BuildContext context, DateTime currentDate, TransactionDao dao) {
    final amounts = widget.movement.paymentAmounts ?? [];
    final amountDaily = amounts.isNotEmpty ? amounts[0] : 0.0;
    
    // Rango: Todo el día de hoy
    final startDay = DateTime(currentDate.year, currentDate.month, currentDate.day, 0, 0);
    final endDay = DateTime(currentDate.year, currentDate.month, currentDate.day, 23, 59);

    return _PaymentButton(
      label: "Día ${DateFormat('dd/MM').format(currentDate)}",
      overrideStartCheck: startDay,
      overrideEndCheck: endDay,
      dateExpected: currentDate,
      parentIncome: widget.movement,
      amountToPay: amountDaily,
      currentDate: currentDate,
      dao: dao,
      isEnabled: true,
      onPaymentSuccess: _refresh,
    );
  }

  // --- 2. CONTROL SEMANAL ---
  Widget _buildWeeklyControls(BuildContext context, DateTime currentDate, TransactionDao dao) {
    final amounts = widget.movement.paymentAmounts ?? [];
    final amountWeek = amounts.isNotEmpty ? amounts[0] : 0.0;
    
    // Obtenemos el día configurado (1=Lunes)
    final configDay = (widget.movement.paymentDays?.isNotEmpty == true) ? widget.movement.paymentDays![0] : 1;

    // Calculamos la fecha de ese día en la semana actual
    // Truco: Encontrar el lunes y sumar (configDay - 1)
    final currentWeekday = currentDate.weekday;
    final monday = currentDate.subtract(Duration(days: currentWeekday - 1));
    final targetDate = monday.add(Duration(days: configDay - 1));

    // Rango de validación: Ese día completo
    final startDay = DateTime(targetDate.year, targetDate.month, targetDate.day, 0, 0);
    final endDay = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59);

    return _PaymentButton(
      label: "Semana del ${monday.day} ${DateFormat('MMM', 'es').format(monday)}",
      overrideStartCheck: startDay,
      overrideEndCheck: endDay,
      dateExpected: targetDate, // Se guarda con la fecha del día de cobro
      parentIncome: widget.movement,
      amountToPay: amountWeek,
      currentDate: currentDate,
      dao: dao,
      isEnabled: true,
      onPaymentSuccess: _refresh,
    );
  }

  // --- 3. CONTROL MENSUAL ---
  Widget _buildMonthlyControls(BuildContext context, DateTime currentDate, TransactionDao dao) {
    final amounts = widget.movement.paymentAmounts ?? [];
    final amountMonth = amounts.isNotEmpty ? amounts[0] : 0.0;

    final configDay = (widget.movement.paymentDays?.isNotEmpty == true) ? widget.movement.paymentDays![0] : 1;
    final lastDayOfMonth = DateTime(currentDate.year, currentDate.month + 1, 0).day;
    // Ajuste: si configura 31 y el mes trae 30, se cobra el 30
    final actualPayDay = (configDay > lastDayOfMonth) ? lastDayOfMonth : configDay;
    
    final targetDate = DateTime(currentDate.year, currentDate.month, actualPayDay);
    
    // Rango: Todo el mes (para evitar cobros dobles)
    final startMonth = DateTime(currentDate.year, currentDate.month, 1);
    final endMonth = DateTime(currentDate.year, currentDate.month + 1, 0, 23, 59, 59);

    return _PaymentButton(
      label: "Mes de ${DateFormat('MMMM', 'es').format(currentDate)}",
      overrideStartCheck: startMonth,
      overrideEndCheck: endMonth,
      dateExpected: targetDate,
      parentIncome: widget.movement,
      amountToPay: amountMonth,
      currentDate: currentDate,
      dao: dao,
      isEnabled: true,
      onPaymentSuccess: _refresh,
    );
  }

  // --- 4. CONTROL QUINCENAL (INTACTO) ---
  Widget _buildBiweeklyControls(BuildContext context, DateTime currentDate, TransactionDao dao) {
    final amounts = widget.movement.paymentAmounts ?? [];
    final amount15 = amounts.isNotEmpty ? amounts[0] : 0.0;
    final amount30 = amounts.length > 1 ? amounts[1] : amount15;

    final startQ1 = DateTime(currentDate.year, currentDate.month, 1);
    final endQ1 = DateTime(currentDate.year, currentDate.month, 15, 23, 59, 59);
    
    final startQ2 = DateTime(currentDate.year, currentDate.month, 16);
    final endQ2 = DateTime(currentDate.year, currentDate.month + 1, 0, 23, 59, 59);

    return Column(
      children: [
        _PaymentButton(
          label: "1ª Quincena (Día 15)",
          overrideStartCheck: startQ1,
          overrideEndCheck: endQ1,
          dateExpected: DateTime(currentDate.year, currentDate.month, 15),
          parentIncome: widget.movement,
          amountToPay: amount15, 
          currentDate: currentDate, 
          dao: dao,
          isEnabled: true,
          onPaymentSuccess: _refresh,
        ),
        const Gap(12),
        FutureBuilder<bool>(
          future: dao.isPaymentMade(recurringId: widget.movement.id, start: startQ1, end: endQ1),
          builder: (context, snapshot) {
            final isFirstPaid = snapshot.data ?? false;
            return _PaymentButton(
              label: "2ª Quincena (Fin de Mes)",
              overrideStartCheck: startQ2,
              overrideEndCheck: endQ2,
              dateExpected: DateTime(currentDate.year, currentDate.month + 1, 0),
              parentIncome: widget.movement,
              amountToPay: amount30, 
              currentDate: currentDate,
              dao: dao,
              isEnabled: isFirstPaid, 
              lockedMessage: "Cobra la 1ª quincena primero",
              onPaymentSuccess: _refresh,
            );
          },
        ),
      ],
    );
  }

  // --- EDICIÓN AVANZADA (CON SELECTORES DE DÍA) ---
  void _showEditDialog(BuildContext context) {
    final titleCtrl = TextEditingController(text: widget.movement.title);
    
    final currentAmounts = widget.movement.paymentAmounts ?? [];
    double val1 = currentAmounts.isNotEmpty ? currentAmounts[0] : 0.0;
    double val2 = (currentAmounts.length > 1) ? currentAmounts[1] : val1;

    final amount1Ctrl = TextEditingController(text: val1.toString());
    final amount2Ctrl = TextEditingController(text: val2.toString());

    final isBiweekly = widget.movement.frequency == Frequency.biweekly;
    final isWeekly = widget.movement.frequency == Frequency.weekly;
    final isMonthly = widget.movement.frequency == Frequency.monthly;

    // Día actual configurado (si existe, sino 1)
    int selectedDay = (widget.movement.paymentDays?.isNotEmpty == true) ? widget.movement.paymentDays![0] : 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Editar Ingreso"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Nombre", prefixIcon: Icon(Icons.label_outline))),
                  const Gap(15),
                  
                  // CAMPOS DE MONTO
                  if (isBiweekly) ...[
                    TextField(controller: amount1Ctrl, decoration: const InputDecoration(labelText: "Monto Día 15", prefixIcon: Icon(Icons.attach_money)), keyboardType: TextInputType.number),
                    const Gap(10),
                    TextField(controller: amount2Ctrl, decoration: const InputDecoration(labelText: "Monto Día Último", prefixIcon: Icon(Icons.attach_money)), keyboardType: TextInputType.number),
                  ] else ...[
                    TextField(controller: amount1Ctrl, decoration: const InputDecoration(labelText: "Monto", prefixIcon: Icon(Icons.attach_money)), keyboardType: TextInputType.number),
                  ],

                  const Gap(15),

                  // SELECTOR DE DÍA (SEMANAL)
                  if (isWeekly) ...[
                    const Text("Día de cobro:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    DropdownButton<int>(
                      value: selectedDay,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 1, child: Text("Lunes")),
                        DropdownMenuItem(value: 2, child: Text("Martes")),
                        DropdownMenuItem(value: 3, child: Text("Miércoles")),
                        DropdownMenuItem(value: 4, child: Text("Jueves")),
                        DropdownMenuItem(value: 5, child: Text("Viernes")),
                        DropdownMenuItem(value: 6, child: Text("Sábado")),
                        DropdownMenuItem(value: 7, child: Text("Domingo")),
                      ], 
                      onChanged: (val) => setStateDialog(() => selectedDay = val!)
                    ),
                  ],

                  // SELECTOR DE DÍA (MENSUAL)
                  if (isMonthly) ...[
                    const Text("Día del mes:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    DropdownButton<int>(
                      value: selectedDay,
                      isExpanded: true,
                      menuMaxHeight: 200, // Hace scroll si la lista es larga
                      items: List.generate(31, (index) => DropdownMenuItem(value: index + 1, child: Text("Día ${index + 1}"))),
                      onChanged: (val) => setStateDialog(() => selectedDay = val!)
                    ),
                  ],

                  const Gap(25),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmDelete(context);
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text("Eliminar Ingreso", style: TextStyle(color: Colors.red)),
                    ),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
              ElevatedButton(
                onPressed: () async {
                  final newTitle = titleCtrl.text;
                  final amt1 = double.tryParse(amount1Ctrl.text) ?? 0.0;
                  final amt2 = double.tryParse(amount2Ctrl.text) ?? 0.0;
                  
                  final updatedMovement = widget.movement..title = newTitle;
                  
                  if (isBiweekly) {
                     updatedMovement.paymentAmounts = [amt1, amt2];
                  } else {
                     updatedMovement.paymentAmounts = [amt1];
                  }

                  // GUARDAR DÍA ELEGIDO
                  if (isWeekly || isMonthly) {
                    updatedMovement.paymentDays = [selectedDay];
                  }

                  await ref.read(recurringDaoProvider).addRecurringMovement(updatedMovement);
                  
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    _refresh();
                  }
                },
                child: const Text("Guardar"),
              )
            ],
          );
        }
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("¿Eliminar?"),
        content: const Text("Se dejará de proyectar este ingreso a futuro."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
               ref.read(recurringDaoProvider).deleteRecurringMovement(widget.movement.id);
               Navigator.pop(ctx); 
               Navigator.pop(context); 
            }, 
            child: const Text("Eliminar")
          )
        ],
      )
    );
  }
}

// --- BOTÓN DE PAGO (GENÉRICO) ---
class _PaymentButton extends StatefulWidget {
  final String label;
  final DateTime overrideStartCheck;
  final DateTime overrideEndCheck;
  final DateTime dateExpected; 
  final RecurringMovement parentIncome;
  final double amountToPay;
  final DateTime currentDate; 
  final TransactionDao dao;
  final bool isEnabled;
  final String? lockedMessage;
  final VoidCallback onPaymentSuccess;

  const _PaymentButton({
    required this.label,
    required this.overrideStartCheck,
    required this.overrideEndCheck,
    required this.dateExpected,
    required this.parentIncome,
    required this.amountToPay,
    required this.currentDate,
    required this.dao,
    required this.isEnabled,
    required this.onPaymentSuccess,
    this.lockedMessage,
  });

  @override
  State<_PaymentButton> createState() => _PaymentButtonState();
}

class _PaymentButtonState extends State<_PaymentButton> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return FutureBuilder<bool>(
      future: widget.dao.isPaymentMade(recurringId: widget.parentIncome.id, start: widget.overrideStartCheck, end: widget.overrideEndCheck),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 50, child: Center(child: LinearProgressIndicator())); 
        final isPaid = snapshot.data!;

        if (isPaid) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.withOpacity(0.5))),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const Gap(12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)), const Text("¡Cobrado!", style: TextStyle(fontSize: 10, color: Colors.green))])),
              ],
            ),
          );
        }

        if (!widget.isEnabled) {
          return Opacity(
            opacity: 0.5,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.lock, color: Colors.grey),
                  const Gap(12),
                  Flexible(child: Text(widget.label, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          );
        }

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: colors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 2),
            icon: const Icon(FontAwesomeIcons.handHoldingDollar, size: 18),
            label: Text("Cobrar \$${widget.amountToPay.toStringAsFixed(0)}"), 
            onPressed: () => _showConfirmDialog(context),
          ),
        );
      },
    );
  }

  void _showConfirmDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.amountToPay.toString());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Confirmar Ingreso", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const Gap(5),
            Text("Se registrará con fecha: ${DateFormat('dd/MM/yyyy').format(widget.dateExpected)}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Gap(20),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              autofocus: false, // Teclado no salta auto
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.attach_money, color: Colors.green), border: OutlineInputBorder()),
            ),
            const Gap(20),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(controller.text) ?? 0.0;
                if (amount > 0) {
                  final newTx = FinancialTransaction()
                    ..amount = amount
                    ..note = "Cobro: ${widget.label}"
                    ..date = widget.dateExpected 
                    ..type = TransactionType.income
                    ..categoryName = widget.parentIncome.title
                    ..categoryIconCode = FontAwesomeIcons.sackDollar.codePoint
                    ..colorValue = Colors.green.value
                    ..parentRecurringId = widget.parentIncome.id;

                  await widget.dao.addTransaction(newTx);
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    widget.onPaymentSuccess();
                  }
                }
              },
              child: const Text("Confirmar"),
            )
          ],
        ),
      ),
    );
  }
}