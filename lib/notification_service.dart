import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Returns true if the current platform supports local notifications
  bool get _isSupported =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> init() async {
    if (_initialized || !_isSupported) return;

    tz.initializeTimeZones();
    final TimezoneInfo tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
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
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    if (!_isSupported) return false;

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      return await iosPlugin.requestPermissions(
              alert: true, badge: true, sound: true) ??
          false;
    }
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      return await androidPlugin.requestNotificationsPermission() ?? false;
    }
    return false;
  }

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'task_reminders',
    'Task Reminders',
    channelDescription: 'Reminders for your scheduled tasks',
    importance: Importance.max,
    priority: Priority.high,
  );

  static const NotificationDetails _notifDetails = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  Future<void> scheduleTaskNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (!_isSupported) return;
    await init();
    if (scheduledTime.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: _notifDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> scheduleTaskNotificationWithReminder({
    required int id,
    required String taskName,
    required DateTime scheduledTime,
  }) async {
    if (!_isSupported) return;

    // Main: at exact due time
    await scheduleTaskNotification(
      id: id,
      title: '⏰ Task Due',
      body: taskName,
      scheduledTime: scheduledTime,
    );
    // 5-min early reminder
    final reminderTime = scheduledTime.subtract(const Duration(minutes: 5));
    if (reminderTime.isAfter(DateTime.now())) {
      await scheduleTaskNotification(
        id: id + 100000,
        title: '⚡ Due in 5 minutes',
        body: taskName,
        scheduledTime: reminderTime,
      );
    }
  }

  Future<void> cancelTaskNotification(int id) async {
    if (!_isSupported) return;
    await _plugin.cancel(id: id);
    await _plugin.cancel(id: id + 100000);
  }

  Future<void> cancelAll() async {
    if (!_isSupported) return;
    await _plugin.cancelAll();
  }

  static int taskId(String taskName, String dateStr) =>
      (taskName + dateStr).hashCode.abs() % 100000;
}

