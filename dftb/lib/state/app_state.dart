import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/alarm_tone.dart';
import '../models/app_mode.dart';
import '../models/brush_session.dart';
import '../models/notification_models.dart';
import '../models/routine_copy.dart';
import '../models/user_settings.dart';
import '../models/verification_method.dart';
import '../services/notification_repository.dart';
import '../services/notification_scheduler.dart';
import '../services/session_repository.dart';
import '../services/settings_store.dart';

class AppState extends ChangeNotifier {
  AppState(this._store, this._sessions, this._notifications, this._scheduler);

  final SettingsStore _store;
  final SessionRepository _sessions;
  final NotificationRepository _notifications;
  final NotificationScheduler _scheduler;

  UserSettings _settings = UserSettings.defaults();
  bool _isReady = false;
  bool _isAlarmOpen = false;
  bool _isAlarmMode = false;
  RoutinePhase? _activeRoutinePhase;
  RoutinePhase? _routinePhaseOverride;
  bool _sleepModeActive = false;
  bool _isDeveloperMode = false;
  String? _activeWindowId;
  AlarmState? _alarmState;

  UserSettings get settings => _settings;
  bool get isReady => _isReady;
  bool get isAlarmOpen => _isAlarmOpen;
  bool get isAlarmMode => _isAlarmMode;
  RoutinePhase get routinePhase =>
      _activeRoutinePhase ??
      _routinePhaseOverride ??
      _routinePhaseFor(DateTime.now());
  RoutinePhase? get routinePhaseOverride => _routinePhaseOverride;
  bool get sleepModeActive => _sleepModeActive;
  bool get isDeveloperMode => _isDeveloperMode;

  bool get isBrushedTonight => _settings.lastBrushDate == _todayKey();
  bool get supportsSnooze => _snoozeConfigFor(_settings.mode) != null;
  bool get canSnooze => snoozeRemaining > 0;
  int get snoozeRemaining {
    final config = _snoozeConfigFor(_settings.mode);
    if (config == null) return 0;
    final used = _alarmState?.snoozeCount ?? 0;
    final remaining = config.maxCount - used;
    return remaining.clamp(0, config.maxCount).toInt();
  }

  Duration? get snoozeDuration => _snoozeConfigFor(_settings.mode)?.duration;
  String? get snoozeLabel {
    final config = _snoozeConfigFor(_settings.mode);
    if (config == null) return null;
    if (snoozeRemaining <= 0) {
      return 'No snoozes left';
    }
    final minutes = config.duration.inMinutes;
    return 'Snooze $minutes min ($snoozeRemaining left)';
  }

  Future<void> load() async {
    _settings = await _store.loadSettings();
    _isDeveloperMode = await _store.loadDeveloperMode();
    await _scheduler.initialize(onNotificationTap: _handleNotificationTap);
    _isReady = true;
    await _refreshSchedule();
    await _syncActiveDeliveries();
    notifyListeners();
  }

  void completeOnboarding({
    required String name,
    required String bedtimeStart,
    required AppMode mode,
    required VerificationMethod method,
  }) {
    _settings = _settings.copyWith(
      isOnboarded: true,
      name: name,
      bedtimeStart: bedtimeStart,
      mode: mode,
      verificationMethod: method,
    );
    _persist();
    unawaited(_refreshSchedule());
    notifyListeners();
  }

  void updateSettings(UserSettings settings) {
    _settings = settings;
    _persist();
    unawaited(_refreshSchedule());
    notifyListeners();
  }

  void updateBedtime({String? start, String? end}) {
    _settings = _settings.copyWith(
      bedtimeStart: start ?? _settings.bedtimeStart,
      bedtimeEnd: end ?? _settings.bedtimeEnd,
    );
    _persist();
    unawaited(_refreshSchedule());
    notifyListeners();
  }

  void updateMode(AppMode mode) {
    _settings = _settings.copyWith(mode: mode);
    _persist();
    unawaited(_refreshSchedule());
    notifyListeners();
  }

  void updateVerificationMethod(VerificationMethod method) {
    _settings = _settings.copyWith(verificationMethod: method);
    _persist();
    unawaited(_refreshSchedule());
    notifyListeners();
  }

  void updateAlarmTone(AlarmTone tone) {
    _settings = _settings.copyWith(alarmTone: tone);
    _persist();
    unawaited(_refreshSchedule());
    notifyListeners();
  }

  Future<void> markBrushed({bool wasLate = false}) async {
    final completionTime = DateTime.now();
    final windowId = _activeWindowId;
    await _recordVerificationSuccess(completionTime);
    final late = wasLate || _isLateCompletion(completionTime);
    await _sessions.addSession(
      BrushSession(
        timestamp: completionTime,
        method: _settings.verificationMethod,
        wasLate: late,
        durationSeconds: 120,
      ),
    );
    final today = _todayKey();
    final yesterday = _yesterdayKey();
    final last = _settings.lastBrushDate;
    int nextStreak = _settings.streak;

    if (last == today) {
      nextStreak = _settings.streak;
    } else if (last == yesterday) {
      nextStreak = _settings.streak + 1;
    } else {
      nextStreak = 1;
    }

    _settings = _settings.copyWith(
      streak: nextStreak,
      lastBrushDate: today,
      lastBrushTime: completionTime.toIso8601String(),
    );
    _isAlarmOpen = false;
    _isAlarmMode = false;
    _activeRoutinePhase = null;
    _sleepModeActive = false;
    _activeWindowId = null;
    _alarmState = null;
    _persist();
    if (windowId != null) {
      await _notifications.clearAlarmState(windowId);
    }
    await _scheduler.cancelAll();
    await _refreshSchedule();
    notifyListeners();
  }

  void openAlarm() {
    _isAlarmOpen = true;
    _isAlarmMode = true;
    _activeRoutinePhase =
        _routinePhaseOverride ?? _routinePhaseFor(DateTime.now());
    unawaited(_setAlarmState(AlarmStatus.ringing));
    notifyListeners();
  }

  void closeAlarm() {
    _isAlarmOpen = false;
    _isAlarmMode = false;
    _activeRoutinePhase = null;
    notifyListeners();
  }

  Future<void> handleAppResumed() async {
    if (!_isReady) return;
    if (!_settings.isOnboarded) return;
    final shouldReschedule = await _shouldReschedule();
    if (shouldReschedule) {
      await _refreshSchedule();
    }
    await _syncActiveDeliveries();
  }

  Future<void> syncNotificationDeliveries() async {
    if (!_isReady) return;
    await _syncActiveDeliveries();
  }

  Future<void> recordVerificationFailure(
    VerificationFailureReason reason,
  ) async {
    await _recordVerificationAttempt(
      result: VerificationResult.failure,
      failureReason: reason,
    );
  }

  Future<void> recordVerificationCanceled() async {
    await _recordVerificationAttempt(result: VerificationResult.canceled);
  }

  void openVerification() {
    _isAlarmOpen = true;
    _isAlarmMode = false;
    _activeRoutinePhase =
        _routinePhaseOverride ?? _routinePhaseFor(DateTime.now());
    notifyListeners();
  }

  void setRoutinePhaseOverride(RoutinePhase? phase) {
    _routinePhaseOverride = phase;
    if (_isAlarmOpen) {
      _activeRoutinePhase = phase ?? _routinePhaseFor(DateTime.now());
    }
    notifyListeners();
  }

  void toggleSleepMode() {
    _sleepModeActive = !_sleepModeActive;
    unawaited(_refreshSchedule());
    notifyListeners();
  }

  Future<void> reset() async {
    await _store.clear();
    await _sessions.clearSessions();
    await _notifications.clearAll();
    _settings = UserSettings.defaults();
    _isAlarmOpen = false;
    _isAlarmMode = false;
    _activeRoutinePhase = null;
    _routinePhaseOverride = null;
    _sleepModeActive = false;
    _activeWindowId = null;
    _alarmState = null;
    await _scheduler.cancelAll();
    notifyListeners();
  }

  void toggleDeveloperMode() {
    _isDeveloperMode = !_isDeveloperMode;
    _store.saveDeveloperMode(_isDeveloperMode);
    notifyListeners();
  }

  Future<void> scheduleTestReminder() async {
    await _scheduler.scheduleTestReminder();
  }

  Future<void> scheduleTestAlarm() async {
    await _scheduler.scheduleTestAlarm(tone: _settings.alarmTone);
  }

  Future<void> showTestNotification() async {
    await _scheduler.showTestNotification();
  }

  Future<void> logPendingNotifications() async {
    await _scheduler.logPendingNotifications();
  }

  Future<void> cancelAllNotifications() async {
    await _scheduler.cancelAll();
  }

  Future<void> snoozeAlarm() async {
    final config = _snoozeConfigFor(_settings.mode);
    final windowId = _activeWindowId;
    if (config == null || windowId == null) return;
    if (snoozeRemaining <= 0) return;

    final nextCount = (_alarmState?.snoozeCount ?? 0) + 1;
    final state = AlarmState(
      windowId: windowId,
      status: AlarmStatus.snoozed,
      snoozeCount: nextCount,
      lastChangedAt: DateTime.now(),
    );
    _alarmState = state;
    await _notifications.upsertAlarmState(state);

    closeAlarm();
    await _scheduler.cancelAlarmNotification();
    final schedule = await _scheduler.scheduleSnoozeAlarm(
      windowId: windowId,
      mode: _settings.mode,
      tone: _settings.alarmTone,
      delay: config.duration,
    );
    await _notifications.insertSchedule(schedule);
  }

  void _handleNotificationTap(String? payload) {
    unawaited(_logDeliveryFromPayload(payload));
    final decoded = _scheduler.decodePayload(payload);
    if (decoded?.type == NotificationScheduleType.alarm.storageValue) {
      openAlarm();
      return;
    }
    openVerification();
  }

  void _persist() {
    _store.saveSettings(_settings);
  }

  Future<void> _refreshSchedule() async {
    if (!_settings.isOnboarded) {
      await _scheduler.cancelAll();
      _activeWindowId = null;
      return;
    }
    final plan = await _scheduler.scheduleForSettings(
      settings: _settings,
      sleepModeActive: _sleepModeActive,
    );
    await _notifications.savePlan(plan);
    _activeWindowId = plan.window.id;
    await _store.saveLastScheduleAt(DateTime.now());
    final timezone = await _scheduler.getLocalTimezone();
    await _store.saveLastTimezone(timezone);
  }

  Future<void> _recordVerificationSuccess(DateTime completionTime) async {
    await _recordVerificationAttempt(
      result: VerificationResult.success,
      startedAt: completionTime,
      completedAt: completionTime,
    );
  }

  Future<void> _recordVerificationAttempt({
    required VerificationResult result,
    VerificationFailureReason? failureReason,
    DateTime? startedAt,
    DateTime? completedAt,
  }) async {
    final windowId = _activeWindowId;
    if (windowId == null) return;
    final timestamp = DateTime.now();
    await _notifications.addVerificationAttempt(
      VerificationAttempt(
        windowId: windowId,
        method: _settings.verificationMethod,
        startedAt: startedAt ?? timestamp,
        completedAt: completedAt ?? timestamp,
        result: result,
        failureReason: failureReason,
      ),
    );
  }

  Future<bool> _shouldReschedule() async {
    final latestWindow = await _notifications.fetchLatestWindow();
    if (latestWindow == null) {
      return true;
    }
    _activeWindowId = latestWindow.id;
    final now = DateTime.now();
    if (now.isAfter(latestWindow.endAt)) {
      return true;
    }
    final lastScheduleAt = await _store.loadLastScheduleAt();
    if (lastScheduleAt == null) {
      return true;
    }
    final lastTimezone = await _store.loadLastTimezone();
    final currentTimezone = await _scheduler.getLocalTimezone();
    if (lastTimezone != null && lastTimezone != currentTimezone) {
      return true;
    }
    final pendingCount = await _scheduler.pendingCount();
    if (pendingCount == 0 &&
        now.isBefore(latestWindow.endAt) &&
        latestWindow.mode != AppMode.gentle) {
      return true;
    }
    return false;
  }

  Future<void> _syncActiveDeliveries() async {
    try {
      final active = await _scheduler.activeNotifications();
      if (active.isEmpty) return;
      for (final notification in active) {
        final payload = _scheduler.decodePayload(notification.payload);
        final scheduleId = payload?.scheduleId;
        if (scheduleId == null || scheduleId.isEmpty) continue;
        final exists = await _notifications.hasDeliveryForSchedule(scheduleId);
        if (exists) continue;
        await _notifications.addDelivery(
          NotificationDelivery(
            scheduleId: scheduleId,
            deliveredAt: DateTime.now(),
            status: NotificationDeliveryStatus.delivered,
            platformId: notification.id?.toString(),
          ),
        );
      }
    } catch (error) {
      debugPrint('[Notifications] Active fetch failed: $error');
    }
  }

  Future<void> _logDeliveryFromPayload(String? payload) async {
    final decoded = _scheduler.decodePayload(payload);
    final scheduleId = decoded?.scheduleId;
    if (scheduleId == null || scheduleId.isEmpty) return;
    final exists = await _notifications.hasDeliveryForSchedule(scheduleId);
    if (exists) return;
    await _notifications.addDelivery(
      NotificationDelivery(
        scheduleId: scheduleId,
        deliveredAt: DateTime.now(),
        status: NotificationDeliveryStatus.delivered,
      ),
    );
  }

  _SnoozeConfig? _snoozeConfigFor(AppMode mode) {
    switch (mode) {
      case AppMode.gentle:
        return null;
      case AppMode.accountability:
        return const _SnoozeConfig(
          maxCount: 2,
          duration: Duration(minutes: 5),
        );
      case AppMode.noExcuses:
        return const _SnoozeConfig(
          maxCount: 1,
          duration: Duration(minutes: 3),
        );
    }
  }

  Future<void> _setAlarmState(AlarmStatus status) async {
    final windowId = _activeWindowId;
    if (windowId == null) return;
    var current = _alarmState;
    if (current == null || current.windowId != windowId) {
      current = await _notifications.fetchAlarmState(windowId);
    }
    final next = AlarmState(
      windowId: windowId,
      status: status,
      snoozeCount: current?.snoozeCount ?? 0,
      lastChangedAt: DateTime.now(),
    );
    _alarmState = next;
    await _notifications.upsertAlarmState(next);
    notifyListeners();
  }

  bool _isLateCompletion(DateTime time) {
    final window = _bedtimeWindowFor(time);
    return time.isAfter(window.end);
  }

  _BedtimeWindow _bedtimeWindowFor(DateTime time) {
    final start = _timeOnDate(_settings.bedtimeStart, time);
    var end = _timeOnDate(_settings.bedtimeEnd, time);
    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }
    return _BedtimeWindow(start, end);
  }

  RoutinePhase _routinePhaseFor(DateTime time) {
    final window = _bedtimeWindowFor(time);
    final isNight = !time.isBefore(window.start) && time.isBefore(window.end);
    return isNight ? RoutinePhase.night : RoutinePhase.morning;
  }

  DateTime _timeOnDate(String raw, DateTime date) {
    final parts = raw.split(':');
    final hour = int.tryParse(parts[0]) ?? 22;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  String _yesterdayKey() {
    final now = DateTime.now().subtract(const Duration(days: 1));
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class _BedtimeWindow {
  const _BedtimeWindow(this.start, this.end);

  final DateTime start;
  final DateTime end;
}

class _SnoozeConfig {
  const _SnoozeConfig({required this.maxCount, required this.duration});

  final int maxCount;
  final Duration duration;
}
