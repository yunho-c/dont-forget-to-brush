import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/app_mode.dart';
import '../models/notification_models.dart';
import '../models/user_settings.dart';

typedef NotificationTapHandler = void Function(String? payload);

class NotificationScheduler {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize({NotificationTapHandler? onNotificationTap}) async {
    if (_initialized) return;
    tz.initializeTimeZones();
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone.identifier));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
      defaultPresentAlert: true,
      defaultPresentSound: true,
      defaultPresentBadge: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
    );
    const macosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
      defaultPresentAlert: true,
      defaultPresentSound: true,
      defaultPresentBadge: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macosSettings,
    );
    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        onNotificationTap?.call(response.payload);
      },
    );
    await _requestPermissions();
    _initialized = true;
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }

  Future<void> scheduleTestReminder({
    Duration delay = const Duration(seconds: 10),
  }) async {
    await initialize();
    final scheduled = tz.TZDateTime.now(tz.local).add(delay);
    await _plugin.zonedSchedule(
      id: 9001,
      title: 'Test reminder',
      body: 'This is a test reminder.',
      scheduledDate: scheduled,
      notificationDetails: _reminderDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'reminder',
    );
  }

  Future<void> scheduleTestAlarm({
    Duration delay = const Duration(seconds: 15),
  }) async {
    await initialize();
    final scheduled = tz.TZDateTime.now(tz.local).add(delay);
    await _plugin.zonedSchedule(
      id: 9002,
      title: 'Test alarm',
      body: 'This is a test alarm.',
      scheduledDate: scheduled,
      notificationDetails: _alarmDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'alarm',
    );
  }

  Future<void> showTestNotification() async {
    await initialize();
    await _plugin.show(
      id: 9003,
      title: 'Test notification',
      body: 'If you see this, delivery works.',
      notificationDetails: _reminderDetails(),
      payload: 'reminder',
    );
  }

  Future<void> logPendingNotifications() async {
    await initialize();
    final pending = await _plugin.pendingNotificationRequests();
    debugPrint(
      '[Notifications] Pending requests: ${pending.length} -> '
      '${pending.map((e) => e.id).toList()}',
    );
  }

  Future<NotificationPlan> scheduleForSettings({
    required UserSettings settings,
    required bool sleepModeActive,
  }) async {
    await initialize();
    await _plugin.cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    final window = _nextWindow(settings, now);
    final windowRecord = BedtimeWindow(
      date: window.start,
      startAt: window.start,
      endAt: window.end,
      mode: settings.mode,
      createdAt: DateTime.now(),
    );
    final schedules = <NotificationSchedule>[];

    final reminderTimes = _reminderTimes(
      mode: settings.mode,
      windowStart: window.start,
      windowEnd: window.end,
      sleepModeActive: sleepModeActive,
      now: now,
    );

    for (int i = 0; i < reminderTimes.length; i += 1) {
      final scheduled = reminderTimes[i];
      if (scheduled.isBefore(now)) continue;
      final copy = _reminderCopy(
        mode: settings.mode,
        index: i,
        total: reminderTimes.length,
        sleepModeActive: sleepModeActive,
      );
      await _plugin.zonedSchedule(
        id: 1000 + i,
        title: copy.title,
        body: copy.body,
        scheduledDate: scheduled,
        notificationDetails: _reminderDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'reminder',
      );
      schedules.add(
        NotificationSchedule(
          windowId: windowRecord.id,
          type: NotificationScheduleType.reminder,
          scheduledAt: scheduled,
          status: NotificationScheduleStatus.scheduled,
          payload: {
            'title': copy.title,
            'body': copy.body,
            'mode': settings.mode.storageValue,
            'sequence': i + 1,
            'total': reminderTimes.length,
          },
        ),
      );
    }

    final alarmTime = _alarmTime(
      mode: settings.mode,
      windowStart: window.start,
      windowEnd: window.end,
      now: now,
    );
    if (alarmTime != null && alarmTime.isAfter(now)) {
      final copy = _alarmCopy(settings.mode);
      await _plugin.zonedSchedule(
        id: 2000,
        title: copy.title,
        body: copy.body,
        scheduledDate: alarmTime,
        notificationDetails: _alarmDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'alarm',
      );
      schedules.add(
        NotificationSchedule(
          windowId: windowRecord.id,
          type: NotificationScheduleType.alarm,
          scheduledAt: alarmTime,
          status: NotificationScheduleStatus.scheduled,
          payload: {
            'title': copy.title,
            'body': copy.body,
            'mode': settings.mode.storageValue,
          },
        ),
      );
    }

    return NotificationPlan(window: windowRecord, schedules: schedules);
  }

  _BedtimeWindow _nextWindow(UserSettings settings, tz.TZDateTime now) {
    final start = _timeOnDate(settings.bedtimeStart, now);
    final end = _timeOnDate(settings.bedtimeEnd, now);
    var windowStart = start;
    var windowEnd = end;
    if (windowEnd.isBefore(windowStart)) {
      windowEnd = windowEnd.add(const Duration(days: 1));
    }
    if (now.isAfter(windowEnd)) {
      windowStart = windowStart.add(const Duration(days: 1));
      windowEnd = windowEnd.add(const Duration(days: 1));
    }
    return _BedtimeWindow(windowStart, windowEnd);
  }

  tz.TZDateTime _timeOnDate(String time, tz.TZDateTime date) {
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 22;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  List<tz.TZDateTime> _reminderTimes({
    required AppMode mode,
    required tz.TZDateTime windowStart,
    required tz.TZDateTime windowEnd,
    required bool sleepModeActive,
    required tz.TZDateTime now,
  }) {
    if (mode == AppMode.gentle && sleepModeActive) {
      return [now.add(const Duration(minutes: 90))];
    }

    final List<tz.TZDateTime> times = [];
    switch (mode) {
      case AppMode.gentle:
        times.add(windowStart);
        times.add(windowStart.add(const Duration(minutes: 45)));
        times.add(windowStart.add(const Duration(minutes: 90)));
        break;
      case AppMode.accountability:
        times.addAll(_intervalTimes(windowStart, windowEnd, 30));
        break;
      case AppMode.noExcuses:
        times.addAll(_intervalTimes(windowStart, windowEnd, 20));
        break;
    }
    return times;
  }

  tz.TZDateTime? _alarmTime({
    required AppMode mode,
    required tz.TZDateTime windowStart,
    required tz.TZDateTime windowEnd,
    required tz.TZDateTime now,
  }) {
    switch (mode) {
      case AppMode.gentle:
        return null;
      case AppMode.accountability:
        return windowEnd;
      case AppMode.noExcuses:
        return windowStart;
    }
  }

  List<tz.TZDateTime> _intervalTimes(
    tz.TZDateTime start,
    tz.TZDateTime end,
    int intervalMinutes,
  ) {
    final List<tz.TZDateTime> times = [];
    var current = start;
    while (!current.isAfter(end)) {
      times.add(current);
      current = current.add(Duration(minutes: intervalMinutes));
    }
    return times;
  }

  NotificationDetails _reminderDetails() {
    const android = AndroidNotificationDetails(
      'bedtime_reminders',
      'Bedtime Reminders',
      channelDescription: 'Gentle bedtime reminders to brush.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: false,
      presentBanner: true,
      presentList: true,
    );
    const macos = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: false,
      presentBanner: true,
      presentList: true,
    );
    return const NotificationDetails(
      android: android,
      iOS: ios,
      macOS: macos,
    );
  }

  NotificationDetails _alarmDetails() {
    const android = AndroidNotificationDetails(
      'bedtime_alarm',
      'Bedtime Alarm',
      channelDescription: 'Alarm requiring verification to dismiss.',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: false,
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    const macos = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: false,
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    return const NotificationDetails(
      android: android,
      iOS: ios,
      macOS: macos,
    );
  }

  Future<void> _requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
    await android?.requestFullScreenIntentPermission();

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    final macos = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    await macos?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  _NotificationCopy _reminderCopy({
    required AppMode mode,
    required int index,
    required int total,
    required bool sleepModeActive,
  }) {
    switch (mode) {
      case AppMode.gentle:
        if (sleepModeActive || total == 1) {
          return const _NotificationCopy(
            'Quick reminder',
            'You still have time tonight.',
          );
        }
        if (index == 0) {
          return const _NotificationCopy(
            'Brush now',
            "Take 90 seconds and you're done for the night.",
          );
        }
        if (index == 1) {
          return const _NotificationCopy(
            'Quick reminder',
            'You still have time tonight.',
          );
        }
        return const _NotificationCopy(
          'Last nudge',
          'One quick brush and you can fully relax.',
        );
      case AppMode.accountability:
        if (index == 0) {
          return const _NotificationCopy(
            'Brush now',
            'Keep the streak going tonight.',
          );
        }
        return const _NotificationCopy(
          'Still time',
          'Brush before the night is over.',
        );
      case AppMode.noExcuses:
        return const _NotificationCopy(
          'Do it now',
          'This is the only chance tonight.',
        );
    }
  }

  _NotificationCopy _alarmCopy(AppMode mode) {
    switch (mode) {
      case AppMode.gentle:
        return const _NotificationCopy(
          'Brush now',
          'Brush to silence this.',
        );
      case AppMode.accountability:
        return const _NotificationCopy(
          'Brush required',
          'Brush to silence this.',
        );
      case AppMode.noExcuses:
        return const _NotificationCopy(
          'Brush now',
          'Brush to silence this.',
        );
    }
  }
}

class _NotificationCopy {
  const _NotificationCopy(this.title, this.body);

  final String title;
  final String body;
}

class _BedtimeWindow {
  const _BedtimeWindow(this.start, this.end);

  final tz.TZDateTime start;
  final tz.TZDateTime end;
}
