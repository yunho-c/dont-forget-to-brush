import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/tag_models.dart';

class TagRepository {
  static const String _tagsKey = 'dftb_tags';

  Future<List<SavedTag>> loadTags() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_tagsKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(SavedTag.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTags(List<SavedTag> tags) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = tags.map((tag) => tag.toJson()).toList();
    await prefs.setString(_tagsKey, jsonEncode(payload));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tagsKey);
  }
}
