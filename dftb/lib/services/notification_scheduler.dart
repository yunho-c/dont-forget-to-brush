import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/alarm_tone.dart';
import '../models/app_mode.dart';
import '../models/notification_models.dart';
import '../models/user_settings.dart';

typedef NotificationTapHandler = void Function(String? payload);

class NotificationScheduler {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  static const int _alarmNotificationId = 2000;

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
      payload: jsonEncode(const {'type': 'reminder', 'scheduleId': 'test'}),
    );
  }

  Future<void> scheduleTestAlarm({
    Duration delay = const Duration(seconds: 15),
    AlarmTone tone = AlarmTone.classic,
  }) async {
    await initialize();
    final scheduled = tz.TZDateTime.now(tz.local).add(delay);
    await _plugin.zonedSchedule(
      id: 9002,
      title: 'Test alarm',
      body: 'This is a test alarm.',
      scheduledDate: scheduled,
      notificationDetails: _alarmDetails(tone),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: jsonEncode(const {'type': 'alarm', 'scheduleId': 'test'}),
    );
  }

  Future<void> showTestNotification() async {
    await initialize();
    await _plugin.show(
      id: 9003,
      title: 'Test notification',
      body: 'If you see this, delivery works.',
      notificationDetails: _reminderDetails(),
      payload: jsonEncode(const {'type': 'reminder', 'scheduleId': 'test'}),
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

  Future<int> pendingCount() async {
    await initialize();
    final pending = await _plugin.pendingNotificationRequests();
    return pending.length;
  }

  Future<List<ActiveNotification>> activeNotifications() async {
    await initialize();
    return _plugin.getActiveNotifications();
  }

  Future<String> getLocalTimezone() async {
    final timezone = await FlutterTimezone.getLocalTimezone();
    return timezone.identifier;
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
      final schedule = NotificationSchedule(
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
      );
      await _plugin.zonedSchedule(
        id: 1000 + i,
        title: copy.title,
        body: copy.body,
        scheduledDate: scheduled,
        notificationDetails: _reminderDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: _encodePayload(schedule),
      );
      schedules.add(schedule);
    }

    final alarmTime = _alarmTime(
      mode: settings.mode,
      windowStart: window.start,
      windowEnd: window.end,
      now: now,
    );
    if (alarmTime != null && alarmTime.isAfter(now)) {
      final schedule = await _scheduleAlarmAt(
        windowId: windowRecord.id,
        scheduledAt: alarmTime,
        mode: settings.mode,
        tone: settings.alarmTone,
      );
      schedules.add(schedule);
    }

    return NotificationPlan(window: windowRecord, schedules: schedules);
  }

  Future<void> cancelAlarmNotification() async {
    await initialize();
    await _plugin.cancel(id: _alarmNotificationId);
  }

  Future<NotificationSchedule> scheduleSnoozeAlarm({
    required String windowId,
    required AppMode mode,
    required AlarmTone tone,
    required Duration delay,
  }) async {
    await initialize();
    final scheduledAt = tz.TZDateTime.now(tz.local).add(delay);
    return _scheduleAlarmAt(
      windowId: windowId,
      scheduledAt: scheduledAt,
      mode: mode,
      tone: tone,
    );
  }

  Future<NotificationSchedule> _scheduleAlarmAt({
    required String windowId,
    required tz.TZDateTime scheduledAt,
    required AppMode mode,
    required AlarmTone tone,
  }) async {
    final copy = _alarmCopy(mode);
    final schedule = NotificationSchedule(
      windowId: windowId,
      type: NotificationScheduleType.alarm,
      scheduledAt: scheduledAt,
      status: NotificationScheduleStatus.scheduled,
      payload: {
        'title': copy.title,
        'body': copy.body,
        'mode': mode.storageValue,
      },
    );
    await _plugin.zonedSchedule(
      id: _alarmNotificationId,
      title: copy.title,
      body: copy.body,
      scheduledDate: scheduledAt,
      notificationDetails: _alarmDetails(tone),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: _encodePayload(schedule),
    );
    return schedule;
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

  NotificationDetails _alarmDetails(AlarmTone tone) {
    final android = AndroidNotificationDetails(
      _alarmChannelId(tone),
      'Bedtime Alarm (${tone.label})',
      channelDescription: 'Alarm requiring verification to dismiss.',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      channelBypassDnd: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      sound: RawResourceAndroidNotificationSound(tone.androidResource),
    );
    final ios = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: false,
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.critical,
      criticalSoundVolume: 1.0,
      sound: tone.iosFilename,
    );
    final macos = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: false,
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.critical,
      criticalSoundVolume: 1.0,
      sound: tone.iosFilename,
    );
    return NotificationDetails(
      android: android,
      iOS: ios,
      macOS: macos,
    );
  }

  String _alarmChannelId(AlarmTone tone) {
    return 'bedtime_alarm_${tone.storageValue}';
  }

  Future<void> _requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    await android?.requestNotificationPolicyAccess();
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
      critical: true,
    );

    final macos = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    await macos?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
      critical: true,
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

  String _encodePayload(NotificationSchedule schedule) {
    return jsonEncode(<String, String>{
      'scheduleId': schedule.id,
      'type': schedule.type.storageValue,
    });
  }

  NotificationPayload? decodePayload(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw == 'alarm' || raw == 'reminder') {
      return NotificationPayload(type: raw);
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return NotificationPayload(
        scheduleId: decoded['scheduleId'] as String?,
        type: decoded['type'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}

class NotificationPayload {
  const NotificationPayload({this.scheduleId, this.type});

  final String? scheduleId;
  final String? type;
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
