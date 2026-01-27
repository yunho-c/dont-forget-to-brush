import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_settings.dart';

class SettingsStore {
  static const String _settingsKey = 'dftb_settings';
  static const String _developerModeKey = 'dftb_developer_mode';
  static const String _lastScheduleAtKey = 'dftb_last_schedule_at';
  static const String _lastTimezoneKey = 'dftb_last_timezone';

  Future<UserSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw == null || raw.isEmpty) {
      return UserSettings.defaults();
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return UserSettings.fromJson(decoded);
    } catch (_) {
      return UserSettings.defaults();
    }
  }

  Future<void> saveSettings(UserSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<bool> loadDeveloperMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_developerModeKey) ?? false;
  }

  Future<void> saveDeveloperMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_developerModeKey, enabled);
  }

  Future<DateTime?> loadLastScheduleAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastScheduleAtKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> saveLastScheduleAt(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastScheduleAtKey, time.toIso8601String());
  }

  Future<String?> loadLastTimezone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastTimezoneKey);
  }

  Future<void> saveLastTimezone(String timezone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastTimezoneKey, timezone);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_settingsKey);
    await prefs.remove(_lastScheduleAtKey);
    await prefs.remove(_lastTimezoneKey);
  }
}
