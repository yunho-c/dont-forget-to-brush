import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_mode.dart';
import '../models/brush_session.dart';
import '../models/user_settings.dart';
import '../models/verification_method.dart';
import '../services/notification_scheduler.dart';
import '../services/session_repository.dart';
import '../services/settings_store.dart';

class AppState extends ChangeNotifier {
  AppState(this._store, this._sessions, this._scheduler);

  final SettingsStore _store;
  final SessionRepository _sessions;
  final NotificationScheduler _scheduler;

  UserSettings _settings = UserSettings.defaults();
  bool _isReady = false;
  bool _isAlarmOpen = false;
  bool _isAlarmMode = false;
  bool _sleepModeActive = false;
  bool _isDeveloperMode = false;

  UserSettings get settings => _settings;
  bool get isReady => _isReady;
  bool get isAlarmOpen => _isAlarmOpen;
  bool get isAlarmMode => _isAlarmMode;
  bool get sleepModeActive => _sleepModeActive;
  bool get isDeveloperMode => _isDeveloperMode;

  bool get isBrushedTonight => _settings.lastBrushDate == _todayKey();

  Future<void> load() async {
    _settings = await _store.loadSettings();
    _isDeveloperMode = await _store.loadDeveloperMode();
    _isReady = true;
    await _refreshSchedule();
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

  Future<void> markBrushed({bool wasLate = false}) async {
    final completionTime = DateTime.now();
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
    _sleepModeActive = false;
    _persist();
    await _scheduler.cancelAll();
    await _refreshSchedule();
    notifyListeners();
  }

  void openAlarm() {
    _isAlarmOpen = true;
    _isAlarmMode = true;
    notifyListeners();
  }

  void closeAlarm() {
    _isAlarmOpen = false;
    _isAlarmMode = false;
    notifyListeners();
  }

  void openVerification() {
    _isAlarmOpen = true;
    _isAlarmMode = false;
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
    _settings = UserSettings.defaults();
    _isAlarmOpen = false;
    _isAlarmMode = false;
    _sleepModeActive = false;
    await _scheduler.cancelAll();
    notifyListeners();
  }

  void toggleDeveloperMode() {
    _isDeveloperMode = !_isDeveloperMode;
    _store.saveDeveloperMode(_isDeveloperMode);
    notifyListeners();
  }

  void _persist() {
    _store.saveSettings(_settings);
  }

  Future<void> _refreshSchedule() async {
    if (!_settings.isOnboarded) {
      await _scheduler.cancelAll();
      return;
    }
    await _scheduler.scheduleForSettings(
      settings: _settings,
      sleepModeActive: _sleepModeActive,
    );
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
