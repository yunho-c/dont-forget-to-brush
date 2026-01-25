import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_settings.dart';

class SettingsStore {
  static const String _settingsKey = 'dftb_settings';

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

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_settingsKey);
  }
}
