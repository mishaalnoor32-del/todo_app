// lib/services/notification_service.dart
//
// Wraps flutter_local_notifications to schedule/cancel task reminders.
//
// -------------------------------------------------------------------------
// LECTURE NOTE: how a reminder gets from "tap Save" to "phone buzzes"
// -------------------------------------------------------------------------
// 1. initialize() runs once at app startup — sets up notification
//    channels and requests OS permission (required on Android 13+ and
//    iOS).
// 2. scheduleReminder() is called by TaskRepository whenever a task is
//    saved with a future reminderTime. We use the task's Hive key as the
//    notification id, so each task maps to exactly one notification —
//    scheduling again with the same id automatically replaces the old one.
// 3. cancelReminder() is called when a task is completed, deleted, or
//    has its reminder cleared, so we don't fire stale notifications.
//
// NOTE ON TIMEZONES: for simplicity, this demo sets the local timezone to
// UTC. That's fine for local testing but means scheduled times are
// interpreted as UTC, not the device's real timezone. For production,
// pair this with a package like `flutter_native_timezone` to detect the
// device's actual IANA zone name and call
// tz.setLocalLocation(tz.getLocation(deviceZoneName)) instead, so
// reminder times line up exactly with the device's clock (and survive
// DST changes correctly).
// -------------------------------------------------------------------------

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.UTC); // see timezone note above

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Android 13+ requires an explicit runtime permission request.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Schedules (or replaces) a reminder notification for a task.
  /// [id] should be the task's unique Hive key.
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await initialize();

    // Don't schedule reminders in the past — the plugin would either
    // ignore or immediately fire them, which isn't what the user wants.
    if (scheduledTime.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          channelDescription: 'Reminders for your pending tasks',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id: id);
  }
}
