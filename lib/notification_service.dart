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

  /// Platforms that support local notifications
  bool get _isSupported =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  Future<void> init() async {
    if (_initialized || !_isSupported) return;

    tz.initializeTimeZones();
    final TimezoneInfo tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS: do NOT request permissions here — we request them separately
    // so we can handle the result. presentAlert/Badge/Sound control
    // foreground display (shown because AppDelegate sets the UNDelegate).
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
      ),
    );
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    if (!_isSupported) return false;

    // iOS / macOS
    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      return await iosPlugin.requestPermissions(
              alert: true, badge: true, sound: true) ??
          false;
    }

    // Android 13+
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      return await androidPlugin.requestNotificationsPermission() ?? false;
    }
    return false;
  }

  // ── Notification detail objects ──────────────────────────────────

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'task_reminders',
    'Task Reminders',
    channelDescription: 'Reminders for your scheduled tasks',
    importance: Importance.max,
    priority: Priority.high,
    // Uses the app launcher icon automatically on Android
  );

  /// iOS details — presentAlert/Badge/Sound show the banner even in foreground
  /// (works because AppDelegate sets UNUserNotificationCenterDelegate).
  static const DarwinNotificationDetails _iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    sound: 'default',
    threadIdentifier: 'planify_tasks',
  );

  static const NotificationDetails _notifDetails = NotificationDetails(
    android: _androidDetails,
    iOS: _iosDetails,
    macOS: _iosDetails,
  );

  // ── Schedule ─────────────────────────────────────────────────────

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
      id,                          // positional — v20 requires positional id
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      _notifDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // Required for iOS scheduled notifications to fire correctly
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleTaskNotificationWithReminder({
    required int id,
    required String taskName,
    required DateTime scheduledTime,
  }) async {
    if (!_isSupported) return;

    // Main notification: at exact due time
    await scheduleTaskNotification(
      id: id,
      title: '⏰ Task Due',
      body: taskName,
      scheduledTime: scheduledTime,
    );

    // 5-minute early reminder
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
    await _plugin.cancel(id);              // positional in v20
    await _plugin.cancel(id + 100000);
  }

  Future<void> cancelAll() async {
    if (!_isSupported) return;
    await _plugin.cancelAll();
  }

  static int taskId(String taskName, String dateStr) =>
      (taskName + dateStr).hashCode.abs() % 100000;
}