import 'dart:async';
import 'dart:io';
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:isar/isar.dart';
import 'package:intl/intl.dart'; 
// ✅ IMPORTANTE: Necesario para que funcione el formato de fechas en background
import 'package:intl/date_symbol_data_local.dart'; 

import '../../data/local_db/isar_db.dart';
import '../../data/models/recurring_movement.dart';
import '../../data/models/transaction.dart';
import '../../data/models/enums.dart';

// 🛑 MANEJADOR BACKGROUND (App Cerrada)
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  print("🛑 BACKGROUND START: Acción -> ${response.actionId}");

  try {
    // 1. Inicialización de Flutter
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized(); 

    // 2. 🔥 ARREGLO DEL CRASH: Inicializar datos de fecha (Español)
    // Sin esto, DateFormat falla en el hilo secundario
    await initializeDateFormatting('es', null);

    // 3. Configurar Timezone
    tz.initializeTimeZones();
    try { tz.setLocalLocation(tz.getLocation('America/Caracas')); } catch (_) { try { tz.setLocalLocation(tz.UTC); } catch (_) {} }

    // 4. Inicializar Plugin
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    await flutterLocalNotificationsPlugin.initialize(const InitializationSettings(android: initializationSettingsAndroid));
    
    // 5. Abrir Base de Datos
    final isarService = IsarService();
    final db = await isarService.openDB();
    
    // 6. Ejecutar Lógica
    final service = NotificationService(); 
    await service._handleActionLogic(db, response.actionId, response.payload);

  } catch (e, stackTrace) {
    print("❌ ERROR CRÍTICO EN BACKGROUND: $e");
    print("Stacktrace: $stackTrace");
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final StreamController<String?> selectNotificationStream = StreamController<String?>.broadcast();

  Future<void> init() async {
    // También inicializamos aquí por si acaso se llama directo
    await initializeDateFormatting('es', null);
    
    tz.initializeTimeZones();
    try { tz.setLocalLocation(tz.getLocation('America/Caracas')); } catch (_) { try { tz.setLocalLocation(tz.UTC); } catch (_) {} }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(android: initializationSettingsAndroid),
      onDidReceiveNotificationResponse: (response) async {
        print("🔔 FOREGROUND EVENT: ${response.actionId}");
        
        if (response.actionId == 'action_pay_yes' || response.actionId == 'action_postpone') {
           try {
             final isarService = IsarService();
             final db = await isarService.db; 
             await _handleActionLogic(db, response.actionId, response.payload);
           } catch (e) {
             print("❌ Error en lógica foreground: $e");
           }
        } else {
           selectNotificationStream.add(response.payload);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    if (Platform.isAndroid) {
      final androidImp = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImp?.requestNotificationsPermission();
      await androidImp?.requestExactAlarmsPermission();
    }
  }

  // --- LÓGICA CENTRAL ---
  Future<void> _handleActionLogic(Isar db, String? actionId, String? payload) async {
    if (payload == null) return;
    
    final parts = payload.split('|');
    final incomeId = int.parse(parts[0]);
    final income = await db.recurringMovements.get(incomeId);

    if (income == null) {
      print("⚠️ Ingreso ID $incomeId no encontrado.");
      return;
    }

    // Recuperar fecha programada para saber el monto exacto
    DateTime targetDate;
    if (parts.length > 1) {
      try {
        targetDate = DateTime.parse(parts[1]);
      } catch (_) {
        targetDate = _calculateNextPaymentDate(income)?.toDateTime() ?? DateTime.now();
      }
    } else {
       targetDate = _calculateNextPaymentDate(income)?.toDateTime() ?? DateTime.now();
    }

    if (actionId == 'action_pay_yes') {
      print("✅ PROCESANDO PAGO AUTOMÁTICO: ${income.title}");
      await _processPayment(db, income, targetDate);
    
    } else if (actionId == 'action_postpone') {
      print("💤 POSPONIENDO: ${income.title}");
      await _postponeNotification(income);
    }
  }

  Future<void> _processPayment(Isar db, RecurringMovement income, DateTime targetDate) async {
    final now = DateTime.now();
    
    // Usamos targetDate (la fecha de la notificación) para determinar si es quincena 1 o 2
    double amount = _getAmountForDate(income, tz.TZDateTime.from(targetDate, tz.local));

    // Esto era lo que causaba el crash antes (ya arreglado con initializeDateFormatting)
    String noteText = _generateNoteText(income, targetDate);

    final newTx = FinancialTransaction()
      ..amount = amount
      ..note = noteText
      ..date = now 
      ..type = TransactionType.income
      ..categoryName = income.title 
      ..categoryIconCode = 0xf0d6
      ..colorValue = 0xFF4CAF50
      ..parentRecurringId = income.id;

    await db.writeTxn(() async {
      await db.financialTransactions.put(newTx);
    });
    
    print("✅ Transacción GUARDADA: \$$amount. Nota: $noteText");
    
    await _scheduleNextForIncome(income);
  }

  Future<void> _postponeNotification(RecurringMovement income) async {
    final now = tz.TZDateTime.now(tz.local);
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrow7pm = tz.TZDateTime(tz.local, tomorrow.year, tomorrow.month, tomorrow.day, 19, 0, 0);
    
    final payload = "${income.id}|${tomorrow7pm.toIso8601String()}";
    
    await _scheduleZoneNotification(
      id: income.id,
      title: "⏰ Recordatorio: ${income.title}",
      body: "Pospusiste este cobro. ¿Ya lo recibiste?",
      scheduledDate: tomorrow7pm,
      payload: payload
    );
  }

  Future<void> scheduleAllNotifications(List<RecurringMovement> incomes) async {
    await flutterLocalNotificationsPlugin.cancelAll(); 
    print("🔄 Reprogramando ${incomes.length} alarmas limpias...");
    
    for (var income in incomes) {
      await _scheduleNextForIncome(income);
    }
  }

  Future<void> _scheduleNextForIncome(RecurringMovement income) async {
    final tz.TZDateTime? nextDate = _calculateNextPaymentDate(income);
    
    if (nextDate != null) {
      double amount = _getAmountForDate(income, nextDate);
      
      final payload = "${income.id}|${nextDate.toIso8601String()}";
      print("📅 Alarma: ${income.title} -> $nextDate (Monto: $amount)");

      await _scheduleZoneNotification(
        id: income.id,
        title: "¡💰 Ha llegado tu pago de ${income.title}!",
        body: "¿Recibiste los \$${amount.toStringAsFixed(2)}? Toca para opciones.",
        scheduledDate: nextDate,
        payload: payload
      );
    }
  }

  // --- LÓGICA DE NEGOCIO ---

  double _getAmountForDate(RecurringMovement income, tz.TZDateTime date) {
    if (income.frequency == Frequency.biweekly) {
      // Si el día de la notificación era > 15, paga el 2do monto
      if (date.day > 15) {
        if ((income.paymentAmounts?.length ?? 0) > 1) {
          return income.paymentAmounts![1];
        }
      }
      return (income.paymentAmounts?.isNotEmpty == true) ? income.paymentAmounts![0] : 0.0;
    }
    return (income.paymentAmounts?.isNotEmpty == true) ? income.paymentAmounts![0] : 0.0;
  }

  String _generateNoteText(RecurringMovement income, DateTime date) {
    if (income.frequency == Frequency.biweekly) {
      if (date.day > 15) {
        return "Cobro: 2ª Quincena (${DateFormat('MMM', 'es').format(date)})";
      } else {
        return "Cobro: 1ª Quincena (${DateFormat('MMM', 'es').format(date)})";
      }
    } else if (income.frequency == Frequency.monthly) {
        return "Cobro: Mes de ${DateFormat('MMMM', 'es').format(date)}";
    }
    return "Cobro Automático: ${income.title}";
  }

  tz.TZDateTime? _calculateNextPaymentDate(RecurringMovement income) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime candidateDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 19, 0, 0);

    if (now.isAfter(candidateDate)) {
      candidateDate = candidateDate.add(const Duration(days: 1));
    }

    for (int i = 0; i < 60; i++) {
      if (_matchesFrequency(income, candidateDate)) {
        return candidateDate;
      }
      candidateDate = candidateDate.add(const Duration(days: 1));
    }
    return null;
  }

  bool _matchesFrequency(RecurringMovement income, DateTime date) {
    switch (income.frequency) {
      case Frequency.daily: return true;
      case Frequency.weekly:
        final userDay = (income.paymentDays?.isNotEmpty == true) ? income.paymentDays![0] : 1;
        return date.weekday == userDay;
      case Frequency.biweekly:
        final lastDayOfMonth = DateTime(date.year, date.month + 1, 0).day;
        return date.day == 15 || date.day == lastDayOfMonth;
      case Frequency.monthly:
        final userDay = (income.paymentDays?.isNotEmpty == true) ? income.paymentDays![0] : 1;
        final lastDayOfMonth = DateTime(date.year, date.month + 1, 0).day;
        final targetDay = (userDay > lastDayOfMonth) ? lastDayOfMonth : userDay;
        return date.day == targetDay;
      default: return false;
    }
  }

  Future<void> _scheduleZoneNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'finapp_channel_prod', 
      'Recordatorios de Ingresos',
      channelDescription: 'Canal principal de cobros',
      importance: Importance.max, priority: Priority.high,
      playSound: true, enableVibration: true, fullScreenIntent: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('action_pay_yes', 'Sí, Cobrar', showsUserInterface: false, cancelNotification: true),
        AndroidNotificationAction('action_edit', 'Otro Monto', showsUserInterface: true, cancelNotification: true),
        AndroidNotificationAction('action_postpone', 'Aún no', showsUserInterface: false, cancelNotification: true),
      ],
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id, title, body, scheduledDate,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}

extension TZConvert on tz.TZDateTime {
  DateTime toDateTime() => DateTime(year, month, day, hour, minute, second);
}