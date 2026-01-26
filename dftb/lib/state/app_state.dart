import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_mode.dart';
import '../models/user_settings.dart';
import '../models/verification_method.dart';
import '../services/settings_store.dart';

class AppState extends ChangeNotifier {
  AppState(this._store);

  final SettingsStore _store;

  UserSettings _settings = UserSettings.defaults();
  bool _isReady = false;
  bool _isAlarmOpen = false;
  bool _isAlarmMode = false;
  bool _sleepModeActive = false;
  bool _isDeveloperMode = false;
  Timer? _sleepTimer;

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
    notifyListeners();
  }

  void updateSettings(UserSettings settings) {
    _settings = settings;
    _persist();
    notifyListeners();
  }

  void updateBedtime({String? start, String? end}) {
    _settings = _settings.copyWith(
      bedtimeStart: start ?? _settings.bedtimeStart,
      bedtimeEnd: end ?? _settings.bedtimeEnd,
    );
    _persist();
    notifyListeners();
  }

  void updateMode(AppMode mode) {
    _settings = _settings.copyWith(mode: mode);
    _persist();
    notifyListeners();
  }

  void updateVerificationMethod(VerificationMethod method) {
    _settings = _settings.copyWith(verificationMethod: method);
    _persist();
    notifyListeners();
  }

  void markBrushed({bool wasLate = false}) {
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
      lastBrushTime: DateTime.now().toIso8601String(),
    );
    _isAlarmOpen = false;
    _isAlarmMode = false;
    _sleepModeActive = false;
    _cancelSleepTimer();
    _persist();
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
    if (_sleepModeActive) {
      _scheduleAlarm();
    } else {
      _cancelSleepTimer();
    }
    notifyListeners();
  }

  Future<void> reset() async {
    await _store.clear();
    _settings = UserSettings.defaults();
    _isAlarmOpen = false;
    _isAlarmMode = false;
    _sleepModeActive = false;
    _cancelSleepTimer();
    notifyListeners();
  }

  void toggleDeveloperMode() {
    _isDeveloperMode = !_isDeveloperMode;
    _store.saveDeveloperMode(_isDeveloperMode);
    notifyListeners();
  }

  void _scheduleAlarm() {
    _cancelSleepTimer();
    _sleepTimer = Timer(const Duration(seconds: 5), () {
      if (!isBrushedTonight) {
        _isAlarmOpen = true;
        _isAlarmMode = true;
        notifyListeners();
      }
    });
  }

  void _cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
  }

  void _persist() {
    _store.saveSettings(_settings);
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
    _cancelSleepTimer();
    super.dispose();
  }
}
