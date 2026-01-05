import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/foundation.dart'; 
import 'dart:ui'; 
import 'dart:io';
import 'dart:async';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart'; 
// Alias solo para Timezone
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/transaction.dart';
import '../../data/models/recurring_movement.dart';
import '../../data/models/category.dart';
import '../../data/models/expense.dart';
import '../../data/models/enums.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  DartPluginRegistrant.ensureInitialized();

  if (notificationResponse.payload == null) return;

  final parts = notificationResponse.payload!.split('|');
  final int incomeId = int.parse(parts[0]);
  final DateTime date = DateTime.parse(parts[1]);

  if (notificationResponse.actionId == 'action_yes') {
    await _processBackgroundPayment(incomeId, date);
  } 
}

Future<void> _processBackgroundPayment(int id, DateTime date) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    Isar isar;
    if (Isar.instanceNames.isEmpty) {
      isar = await Isar.open(
        [FinancialTransactionSchema, RecurringMovementSchema, CategorySchema, ExpenseSchema],
        directory: dir.path,
        inspector: false,
      );
    } else {
      isar = Isar.getInstance()!;
    }

    final income = await isar.recurringMovements.get(id);
    
    if (income != null) {
      double amount = 0.0;
      String note = "Cobro Recurrente";
      final amounts = income.paymentAmounts ?? [];

      if (income.frequency == Frequency.biweekly) {
        final isFirstFortnight = date.day <= 15;
        amount = isFirstFortnight 
            ? (amounts.isNotEmpty ? amounts[0] : 0.0)
            : (amounts.length > 1 ? amounts[1] : (amounts.isNotEmpty ? amounts[0] : 0.0));
        note = isFirstFortnight ? "Cobro: 1ª Quincena (Día 15)" : "Cobro: 2ª Quincena (Fin de Mes)";
      } else if (income.frequency == Frequency.monthly) {
        amount = amounts.isNotEmpty ? amounts[0] : 0.0;
        note = "Cobro: Mensualidad de ${DateFormat('MMMM', 'es').format(date)}";
      } else if (income.frequency == Frequency.weekly) {
        amount = amounts.isNotEmpty ? amounts[0] : 0.0;
        final daysFromMonday = date.weekday - 1;
        final monday = date.subtract(Duration(days: daysFromMonday));
        note = "Cobro: Semana del ${monday.day} ${DateFormat('MMM', 'es').format(monday)}";
      } else if (income.frequency == Frequency.daily) {
        amount = amounts.isNotEmpty ? amounts[0] : 0.0;
        note = "Cobro: Día ${DateFormat('dd/MM').format(date)}";
      }

      final newTx = FinancialTransaction()
        ..amount = amount
        ..note = note
        ..date = date
        ..type = TransactionType.income
        ..categoryName = income.title
        ..categoryIconCode = FontAwesomeIcons.sackDollar.codePoint
        ..colorValue = 0xFF4CAF50 
        ..parentRecurringId = income.id;

      await isar.writeTxn(() async {
        await isar.financialTransactions.put(newTx);
      });
    }
  } catch (e) {
    debugPrint("Error background: $e");
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final StreamController<String?> selectNotificationStream = StreamController<String?>.broadcast();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.actionId == 'action_other') {
          selectNotificationStream.add(response.payload);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
    }
  }

  Future<void> scheduleAllNotifications(List<RecurringMovement> incomes) async {
    await flutterLocalNotificationsPlugin.cancelAll();

    for (var income in incomes) {
      final nextDate = _calculateNextPaymentDate(income);
      if (nextDate != null) {
        double amount = 0.0;
        if (income.frequency == Frequency.biweekly && nextDate.day > 15) {
           amount = (income.paymentAmounts?.length ?? 0) > 1 
              ? income.paymentAmounts![1] 
              : ((income.paymentAmounts?.isNotEmpty ?? false) ? income.paymentAmounts![0] : 0.0);
        } else {
           amount = (income.paymentAmounts?.isNotEmpty == true) ? income.paymentAmounts![0] : 0.0;
        }

        final payload = "${income.id}|${nextDate.toIso8601String()}";

        await _scheduleZoneNotification(
          id: income.id,
          title: "💰 ¡Llegó tu pago: ${income.title}!",
          body: "¿Recibiste los \$${amount.toStringAsFixed(2)}? Toca para confirmar.",
          scheduledDate: nextDate,
          payload: payload
        );
      }
    }
  }

  DateTime? _calculateNextPaymentDate(RecurringMovement income) {
    final now = DateTime.now();
    // ✅ CAMBIO: Hora fijada a las 14:00 (2:00 PM)
    final baseTime = DateTime(now.year, now.month, now.day, 14, 0, 0);
    final searchStart = now.isAfter(baseTime) ? baseTime.add(const Duration(days: 1)) : baseTime;

    DateTime? nextDate;

    if (income.frequency == Frequency.daily) {
      nextDate = searchStart;
    } else if (income.frequency == Frequency.weekly) {
      final userDay = (income.paymentDays?.isNotEmpty == true) ? income.paymentDays![0] : 1;
      DateTime temp = searchStart;
      while (temp.weekday != userDay) {
        temp = temp.add(const Duration(days: 1));
      }
      nextDate = temp;
    } else if (income.frequency == Frequency.monthly) {
      final userDay = (income.paymentDays?.isNotEmpty == true) ? income.paymentDays![0] : 1;
      DateTime temp = searchStart;
      while (true) {
        final lastDayOfMonth = DateTime(temp.year, temp.month + 1, 0).day;
        final targetDay = (userDay > lastDayOfMonth) ? lastDayOfMonth : userDay;
        if (temp.day == targetDay) {
          nextDate = temp;
          break;
        }
        temp = temp.add(const Duration(days: 1));
        if (temp.day == targetDay) { nextDate = temp; break; } 
      }
    } else if (income.frequency == Frequency.biweekly) {
      DateTime temp = searchStart;
      while (true) {
        final lastDay = DateTime(temp.year, temp.month + 1, 0).day;
        if (temp.day == 15 || temp.day == lastDay) {
          nextDate = temp;
          break;
        }
        temp = temp.add(const Duration(days: 1));
      }
    }
    return nextDate;
  }

  Future<void> _scheduleZoneNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'finapp_channel_id', 'Recordatorios de Pago', importance: Importance.max, priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('action_yes', 'Sí, Recibido', showsUserInterface: false, cancelNotification: true),
        AndroidNotificationAction('action_other', 'Otro Monto', showsUserInterface: true, cancelNotification: true),
        AndroidNotificationAction('action_snooze', 'Aún No', showsUserInterface: false, cancelNotification: true),
      ],
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(android: androidPlatformChannelSpecifics),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> showActionNotification({
    required int id,
    required String title,
    required String body,
    required String payload, 
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'finapp_channel_id', 'Recordatorios de Pago', importance: Importance.max, priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('action_yes', 'Sí, Recibido', showsUserInterface: false, cancelNotification: true),
        AndroidNotificationAction('action_other', 'Otro Monto', showsUserInterface: true, cancelNotification: true),
        AndroidNotificationAction('action_snooze', 'Aún No', showsUserInterface: false, cancelNotification: true),
      ],
    );

    await flutterLocalNotificationsPlugin.show(
      id, title, body, 
      const NotificationDetails(android: androidPlatformChannelSpecifics), 
      payload: payload
    );
  }
}