import 'dart:async';
import 'dart:io';
// 1. Solo dejamos los imports necesarios
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/recurring_movement.dart';
import '../../data/models/enums.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  // Lógica de background (si la implementas a futuro)
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final StreamController<String?> selectNotificationStream = StreamController<String?>.broadcast();

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.local); 
    } catch (e) {
      // Fallback si falla la detección automática
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
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
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  Future<void> scheduleAllNotifications(List<RecurringMovement> incomes) async {
    await flutterLocalNotificationsPlugin.cancelAll();

    for (var income in incomes) {
      final tz.TZDateTime? nextDate = _calculateNextPaymentDate(income);
      
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
          title: "💰 ¡Hora de cobrar: ${income.title}!",
          body: "Toca para registrar el pago de \$${amount.toStringAsFixed(2)}",
          scheduledDate: nextDate,
          payload: payload
        );
      }
    }
  }

  tz.TZDateTime? _calculateNextPaymentDate(RecurringMovement income) {
    final now = tz.TZDateTime.now(tz.local);
    // 9:00 AM
    tz.TZDateTime candidateDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9, 0, 0);

    if (now.isAfter(candidateDate)) {
      candidateDate = candidateDate.add(const Duration(days: 1));
    }

    for (int i = 0; i < 45; i++) {
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
      'finapp_channel_id', 'Recordatorios de Pago',
      channelDescription: 'Avisos para registrar tus ingresos',
      importance: Importance.max, priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('action_open', 'Registrar Ahora', showsUserInterface: true),
      ],
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id, title, body, scheduledDate,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}