import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../data/models/recurring_movement.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/transaction.dart';
import '../../../data/daos/transaction_dao.dart'; 
import '../../../logic/providers/database_providers.dart'; 
import '../../../logic/services/notification_service.dart';

class RecurringDetailModal extends ConsumerStatefulWidget {
  final RecurringMovement movement;

  const RecurringDetailModal({super.key, required this.movement});

  @override
  ConsumerState<RecurringDetailModal> createState() => _RecurringDetailModalState();
}

class _RecurringDetailModalState extends ConsumerState<RecurringDetailModal> {
  
  void _refresh() {
    if (mounted) setState(() {});
  }

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
    final currentDate = DateTime.now(); 
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

  // --- CONTROLES DE PAGO (SIN CAMBIOS) ---
  Widget _buildDailyControls(BuildContext context, DateTime currentDate, TransactionDao dao) {
    final amount = (widget.movement.paymentAmounts?.isNotEmpty == true) ? widget.movement.paymentAmounts![0] : 0.0;
    return _PaymentButton(
      label: "Día ${DateFormat('dd/MM').format(currentDate)}",
      overrideStartCheck: DateTime(currentDate.year, currentDate.month, currentDate.day, 0, 0),
      overrideEndCheck: DateTime(currentDate.year, currentDate.month, currentDate.day, 23, 59),
      dateExpected: currentDate,
      parentIncome: widget.movement,
      amountToPay: amount,
      dao: dao,
      isEnabled: true,
      onPaymentSuccess: _refresh,
    );
  }

  Widget _buildWeeklyControls(BuildContext context, DateTime currentDate, TransactionDao dao) {
    final amount = (widget.movement.paymentAmounts?.isNotEmpty == true) ? widget.movement.paymentAmounts![0] : 0.0;
    final configDay = (widget.movement.paymentDays?.isNotEmpty == true) ? widget.movement.paymentDays![0] : 1;
    final currentWeekday = currentDate.weekday;
    final monday = currentDate.subtract(Duration(days: currentWeekday - 1));
    return _PaymentButton(
      label: "Semana del ${monday.day} ${DateFormat('MMM', 'es').format(monday)}",
      overrideStartCheck: DateTime(monday.year, monday.month, monday.day, 0, 0),
      overrideEndCheck: monday.add(const Duration(days: 6, hours: 23, minutes: 59)),
      dateExpected: monday.add(Duration(days: configDay - 1)),
      parentIncome: widget.movement,
      amountToPay: amount,
      dao: dao,
      isEnabled: true,
      onPaymentSuccess: _refresh,
    );
  }

  Widget _buildMonthlyControls(BuildContext context, DateTime currentDate, TransactionDao dao) {
    final amount = (widget.movement.paymentAmounts?.isNotEmpty == true) ? widget.movement.paymentAmounts![0] : 0.0;
    final configDay = (widget.movement.paymentDays?.isNotEmpty == true) ? widget.movement.paymentDays![0] : 1;
    final lastDayOfMonth = DateTime(currentDate.year, currentDate.month + 1, 0).day;
    final actualPayDay = (configDay > lastDayOfMonth) ? lastDayOfMonth : configDay;
    return _PaymentButton(
      label: "Mes de ${DateFormat('MMMM', 'es').format(currentDate)}",
      overrideStartCheck: DateTime(currentDate.year, currentDate.month, 1),
      overrideEndCheck: DateTime(currentDate.year, currentDate.month + 1, 0, 23, 59),
      dateExpected: DateTime(currentDate.year, currentDate.month, actualPayDay),
      parentIncome: widget.movement,
      amountToPay: amount,
      dao: dao,
      isEnabled: true,
      onPaymentSuccess: _refresh,
    );
  }

  Widget _buildBiweeklyControls(BuildContext context, DateTime currentDate, TransactionDao dao) {
    final amounts = widget.movement.paymentAmounts ?? [];
    final amount15 = amounts.isNotEmpty ? amounts[0] : 0.0;
    final amount30 = amounts.length > 1 ? amounts[1] : amount15;

    final startOfMonth = DateTime(currentDate.year, currentDate.month, 1);
    final endOfMonth = DateTime(currentDate.year, currentDate.month + 1, 0, 23, 59, 59);
    final targetDate1 = DateTime(currentDate.year, currentDate.month, 15);
    final targetDate2 = DateTime(currentDate.year, currentDate.month + 1, 0);

    return Column(
      children: [
        _PaymentButton(
          label: "1ª Quincena (Día 15)",
          overrideStartCheck: startOfMonth,
          overrideEndCheck: endOfMonth,
          dateExpected: targetDate1,
          parentIncome: widget.movement,
          amountToPay: amount15, 
          dao: dao,
          isEnabled: true,
          onPaymentSuccess: _refresh,
          customCheck: dao.countPayments(recurringId: widget.movement.id, start: startOfMonth, end: endOfMonth)
              .then((count) => count >= 1),
        ),
        const Gap(12),
        FutureBuilder<int>(
          future: dao.countPayments(recurringId: widget.movement.id, start: startOfMonth, end: endOfMonth),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            final isFirstPaid = count >= 1; 
            return _PaymentButton(
              label: "2ª Quincena (Fin de Mes)",
              overrideStartCheck: startOfMonth,
              overrideEndCheck: endOfMonth,
              dateExpected: targetDate2,
              parentIncome: widget.movement,
              amountToPay: amount30, 
              dao: dao,
              isEnabled: isFirstPaid, 
              lockedMessage: "Cobra la 1ª quincena primero",
              onPaymentSuccess: _refresh,
              customCheck: Future.value(count >= 2), 
            );
          },
        ),
      ],
    );
  }

  // --- LÓGICA DE EDICIÓN Y ELIMINACIÓN CORREGIDA ---

  void _showEditDialog(BuildContext parentContext) {
    final titleCtrl = TextEditingController(text: widget.movement.title);
    
    final currentAmounts = widget.movement.paymentAmounts ?? [];
    double val1 = currentAmounts.isNotEmpty ? currentAmounts[0] : 0.0;
    double val2 = (currentAmounts.length > 1) ? currentAmounts[1] : val1;

    final amount1Ctrl = TextEditingController(text: val1.toString());
    final amount2Ctrl = TextEditingController(text: val2.toString());

    final isBiweekly = widget.movement.frequency == Frequency.biweekly;
    final isWeekly = widget.movement.frequency == Frequency.weekly;
    final isMonthly = widget.movement.frequency == Frequency.monthly;

    int selectedDay = (widget.movement.paymentDays?.isNotEmpty == true) ? widget.movement.paymentDays![0] : 1;

    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (ctxEdit) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Editar Ingreso"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Nombre", prefixIcon: Icon(Icons.label_outline))),
                  const Gap(15),
                  if (isBiweekly) ...[
                    TextField(controller: amount1Ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Monto Día 15", prefixIcon: Icon(Icons.attach_money))),
                    const Gap(10),
                    TextField(controller: amount2Ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Monto Día Último", prefixIcon: Icon(Icons.attach_money))),
                  ] else 
                    TextField(controller: amount1Ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Monto", prefixIcon: Icon(Icons.attach_money))),
                  
                  const Gap(15),
                  if (isWeekly || isMonthly) ...[
                    DropdownButton<int>(
                      value: selectedDay,
                      items: List.generate(isWeekly ? 7 : 31, (i) => DropdownMenuItem(value: i + 1, child: Text(isWeekly ? _getDayName(i + 1) : "Día ${i + 1}"))),
                      onChanged: (v) => setStateDialog(() => selectedDay = v!),
                    )
                  ],

                  const Gap(25),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text("Eliminar Ingreso", style: TextStyle(color: Colors.red)),
                      onPressed: () async {
                        // ✅ PASO 1: Cerrar diálogo de Editar
                        Navigator.of(ctxEdit).pop();
                        
                        // ✅ PASO 2: Pequeña pausa para que termine la animación
                        await Future.delayed(const Duration(milliseconds: 200));

                        // ✅ PASO 3: Verificar si el widget principal sigue vivo
                        if (mounted) {
                          // Llamamos a confirmar usando el contexto del widget padre
                          _confirmDelete(parentContext); 
                        }
                      },
                    ),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctxEdit), child: const Text("Cancelar")),
              ElevatedButton(
                onPressed: () async {
                  // Guardado normal...
                  final newTitle = titleCtrl.text;
                  final amt1 = double.tryParse(amount1Ctrl.text) ?? 0.0;
                  final amt2 = double.tryParse(amount2Ctrl.text) ?? 0.0;
                  widget.movement.title = newTitle;
                  if (isBiweekly) widget.movement.paymentAmounts = [amt1, amt2];
                  else widget.movement.paymentAmounts = [amt1];
                  if (isWeekly || isMonthly) widget.movement.paymentDays = [selectedDay];

                  await ref.read(recurringDaoProvider).addRecurringMovement(widget.movement);
                  final allIncomes = await ref.read(recurringDaoProvider).getAllRecurringMovements();
                  await NotificationService().scheduleAllNotifications(allIncomes);

                  if (mounted) {
                    Navigator.pop(ctxEdit);
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

  void _confirmDelete(BuildContext parentContext) {
    showDialog(
      context: parentContext, 
      barrierDismissible: false,
      builder: (ctxConfirm) => AlertDialog(
        title: const Text("¿Eliminar?"),
        content: const Text("Se borrará este ingreso recurrente."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctxConfirm), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
               // 1. Eliminar de BD
               await ref.read(recurringDaoProvider).deleteRecurringMovement(widget.movement.id);
               
               // 2. Actualizar Notificaciones
               final allIncomes = await ref.read(recurringDaoProvider).getAllRecurringMovements();
               await NotificationService().scheduleAllNotifications(allIncomes);
               
               // 3. SECUENCIA DE CIERRE SEGURA
               if (mounted) {
                 // Cerrar Confirmación
                 Navigator.of(ctxConfirm).pop();
                 
                 // Esperar animación
                 await Future.delayed(const Duration(milliseconds: 100));

                 // Cerrar el Modal de Detalles (BottomSheet)
                 if (parentContext.mounted) {
                    Navigator.of(parentContext).pop(); 
                 }
               }
            }, 
            child: const Text("Eliminar")
          )
        ],
      )
    );
  }

  String _getDayName(int day) {
    const days = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"];
    if (day >= 1 && day <= 7) return days[day - 1];
    return "Día $day";
  }
}

// ... _PaymentButton se mantiene igual ...
class _PaymentButton extends StatefulWidget {
  final String label;
  final DateTime overrideStartCheck;
  final DateTime overrideEndCheck;
  final DateTime dateExpected; 
  final RecurringMovement parentIncome;
  final double amountToPay;
  final TransactionDao dao;
  final bool isEnabled;
  final String? lockedMessage;
  final VoidCallback onPaymentSuccess;
  final Future<bool>? customCheck; 

  const _PaymentButton({
    required this.label,
    required this.overrideStartCheck,
    required this.overrideEndCheck,
    required this.dateExpected,
    required this.parentIncome,
    required this.amountToPay,
    required this.dao,
    required this.isEnabled,
    required this.onPaymentSuccess,
    this.lockedMessage,
    this.customCheck, 
  });

  @override
  State<_PaymentButton> createState() => _PaymentButtonState();
}

class _PaymentButtonState extends State<_PaymentButton> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final checkFuture = widget.customCheck ?? widget.dao.isPaymentMade(
      recurringId: widget.parentIncome.id, 
      start: widget.overrideStartCheck, 
      end: widget.overrideEndCheck
    );

    return FutureBuilder<bool>(
      future: checkFuture,
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
            const Gap(20),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              autofocus: false, 
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
                    ..date = DateTime.now() 
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