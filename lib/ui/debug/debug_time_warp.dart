import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../logic/providers/time_provider.dart';
import '../../logic/providers/database_providers.dart';
import '../../logic/services/notification_service.dart';
import '../../data/models/enums.dart';

class DebugTimeWarp extends ConsumerWidget {
  const DebugTimeWarp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDate = ref.watch(nowProvider);
    final isSimulated = ref.watch(timeControllerProvider) != null;

    return FloatingActionButton.small(
      heroTag: "time_warp_fab",
      backgroundColor: isSimulated ? Colors.purpleAccent : Colors.grey[800],
      child: const Icon(FontAwesomeIcons.bug, color: Colors.white, size: 16),
      onPressed: () => _showDebugMenu(context, ref, currentDate),
    );
  }

  void _showDebugMenu(BuildContext context, WidgetRef ref, DateTime current) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("🐞 Máquina del Tiempo"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Configura el momento exacto para probar.", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
            
            // RELOJ DIGITAL
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.purpleAccent),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('dd MMM yyyy', 'es').format(current).toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    DateFormat('HH:mm').format(current),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.greenAccent, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // BOTÓN MAESTRO
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white
                ),
                icon: const Icon(Icons.edit_calendar),
                label: const Text("Establecer Fecha y Hora"),
                onPressed: () async {
                  // 1. ELEGIR FECHA
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: current,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    locale: const Locale('es', 'ES'),
                  );
                  
                  if (pickedDate != null && context.mounted) {
                    // 2. ELEGIR HORA Y MINUTOS
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(current),
                      helpText: "DEFINE LA HORA (PROBAR 19:00)",
                    );

                    if (pickedTime != null) {
                      final newDateTime = DateTime(
                        pickedDate.year, 
                        pickedDate.month, 
                        pickedDate.day, 
                        pickedTime.hour, 
                        pickedTime.minute
                      );

                      // Guardamos la fecha simulada
                      ref.read(timeControllerProvider.notifier).setSimulatedDate(newDateTime);
                      
                      // Cerramos el menú
                      if (context.mounted) Navigator.pop(ctx);

                      // 🚀 VERIFICAMOS SI TOCA PAGO (Con Delay para salir de la app)
                      _checkAndTriggerNotifications(context, ref, newDateTime);
                    }
                  }
                },
              ),
            ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: () {
                ref.read(timeControllerProvider.notifier).resetToRealDate();
                Navigator.pop(ctx);
              },
              child: const Text("Volver al Presente"),
            ),
          ],
        ),
      ),
    );
  }

  // --- LÓGICA INTELIGENTE DE NOTIFICACIÓN ---
  void _checkAndTriggerNotifications(BuildContext context, WidgetRef ref, DateTime simulationTime) async {
    
    // 1. REGLA: Solo notificamos si son las 7:00 PM (19:00) o más tarde
    if (simulationTime.hour < 19) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🕒 Son las ${simulationTime.hour}:${simulationTime.minute.toString().padLeft(2,'0')}. Hora de cobro: 19:00."))
      );
      return; 
    }

    final recurringDao = ref.read(recurringDaoProvider);
    final transactionDao = ref.read(transactionDaoProvider);
    final incomes = await recurringDao.getAllRecurringMovements();

    bool scheduled = false;

    for (var income in incomes) {
      bool isPaymentDay = false;
      DateTime? targetDate;
      double amountToPay = 0.0;
      
      // Rangos para verificar si ya se pagó
      DateTime? checkStart;
      DateTime? checkEnd;

      // Extraemos la configuración de días (evitamos nulos)
      final daysConfig = income.paymentDays ?? [];

      // ---------------------------------------------------
      // 1. DIARIO: Todos los días
      // ---------------------------------------------------
      if (income.frequency == Frequency.daily) {
        isPaymentDay = true; 
        targetDate = simulationTime;
        amountToPay = (income.paymentAmounts?.isNotEmpty == true) ? income.paymentAmounts![0] : 0.0;
        
        checkStart = DateTime(simulationTime.year, simulationTime.month, simulationTime.day, 0, 0);
        checkEnd = DateTime(simulationTime.year, simulationTime.month, simulationTime.day, 23, 59);
      }

      // ---------------------------------------------------
      // 2. SEMANAL: Día definido en paymentDays[0]
      // ---------------------------------------------------
      else if (income.frequency == Frequency.weekly) {
        // Usamos el primer valor de la lista. (1=Lunes ... 7=Domingo). Por defecto Lunes(1).
        final userWeekday = daysConfig.isNotEmpty ? daysConfig[0] : 1; 

        if (simulationTime.weekday == userWeekday) {
          isPaymentDay = true;
          targetDate = simulationTime;
          amountToPay = (income.paymentAmounts?.isNotEmpty == true) ? income.paymentAmounts![0] : 0.0;
          
          checkStart = DateTime(simulationTime.year, simulationTime.month, simulationTime.day, 0, 0);
          checkEnd = checkStart.add(const Duration(hours: 23, minutes: 59));
        }
      }

      // ---------------------------------------------------
      // 3. MENSUAL: Día definido en paymentDays[0]
      // ---------------------------------------------------
      else if (income.frequency == Frequency.monthly) {
        // Usamos el primer valor de la lista (Día del mes 1-31). Por defecto Día 1.
        final userDay = daysConfig.isNotEmpty ? daysConfig[0] : 1; 
        final lastDayOfCurrentMonth = DateTime(simulationTime.year, simulationTime.month + 1, 0).day;

        // Ajuste inteligente: Si toca el 31, pero estamos en un mes de 30 o 28 días, cobramos el último día.
        int actualPayDay = userDay;
        if (userDay > lastDayOfCurrentMonth) {
          actualPayDay = lastDayOfCurrentMonth;
        }

        if (simulationTime.day == actualPayDay) {
          isPaymentDay = true;
          targetDate = simulationTime; 
          amountToPay = (income.paymentAmounts?.isNotEmpty == true) ? income.paymentAmounts![0] : 0.0;
          
          checkStart = DateTime(simulationTime.year, simulationTime.month, 1); 
          checkEnd = DateTime(simulationTime.year, simulationTime.month, lastDayOfCurrentMonth, 23, 59);
        }
      }

      // ---------------------------------------------------
      // 4. QUINCENAL: 15 y Último
      // ---------------------------------------------------
      else if (income.frequency == Frequency.biweekly) {
        final lastDay = DateTime(simulationTime.year, simulationTime.month + 1, 0).day;
        
        // 1ra Quincena (Día 15)
        if (simulationTime.day == 15) {
          isPaymentDay = true;
          targetDate = DateTime(simulationTime.year, simulationTime.month, 15);
          amountToPay = (income.paymentAmounts?.isNotEmpty == true) ? income.paymentAmounts![0] : 0.0;
          
          checkStart = DateTime(simulationTime.year, simulationTime.month, 1);
          checkEnd = DateTime(simulationTime.year, simulationTime.month, 15, 23, 59);
        } 
        // 2da Quincena (Fin de Mes)
        else if (simulationTime.day == lastDay) {
          isPaymentDay = true;
          targetDate = DateTime(simulationTime.year, simulationTime.month, lastDay);
          amountToPay = (income.paymentAmounts?.length ?? 0) > 1 
              ? income.paymentAmounts![1] 
              : ((income.paymentAmounts?.isNotEmpty ?? false) ? income.paymentAmounts![0] : 0.0);
          
          checkStart = DateTime(simulationTime.year, simulationTime.month, 16);
          checkEnd = DateTime(simulationTime.year, simulationTime.month, lastDay, 23, 59);
        }
      }

      // ---------------------------------------------------
      // EJECUCIÓN
      // ---------------------------------------------------
      if (isPaymentDay && targetDate != null && checkStart != null && checkEnd != null) {
        
        final alreadyPaid = await transactionDao.isPaymentMade(
          recurringId: income.id, 
          start: checkStart, 
          end: checkEnd
        );

        if (!alreadyPaid) {
          scheduled = true;
          // ID|FECHA
          final payload = "${income.id}|${targetDate.toIso8601String()}";
          
          // DELAY DE 5 SEGUNDOS PARA SALIR DE LA APP
          Future.delayed(const Duration(seconds: 5), () {
            NotificationService().showActionNotification(
              id: income.id,
              title: "💰 ¡Llegó tu pago: ${income.title}!",
              body: "¿Recibiste los \$${amountToPay.toStringAsFixed(2)}? (7:00 PM)",
              payload: payload, 
            );
          });
        }
      }
    }

    if (scheduled && context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("🚀 Lanzamiento Iniciado"),
          content: const Text(
            "¡Es día y hora de cobro!\n\n"
            "La notificación llegará en exactamente 5 SEGUNDOS.\n\n"
            "👉 SAL DE LA APP AHORA (Minimízala) para verla llegar en la barra de estado.",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text("Entendido"))
          ],
        )
      );
    } else if (!scheduled && context.mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Al día: No hay pagos pendientes para esta fecha/hora."))
      );
    }
  }
}