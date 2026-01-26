import 'package:sqflite/sqflite.dart';

import '../models/brush_session.dart';
import '../models/weekly_stat.dart';
import 'database_service.dart';

class SessionRepository {
  SessionRepository(this._databaseService);

  final DatabaseService _databaseService;

  Future<void> addSession(BrushSession session) async {
    final db = await _databaseService.database;
    await db.insert(
      'sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearSessions() async {
    final db = await _databaseService.database;
    await db.delete('sessions');
  }

  Future<List<BrushSession>> fetchSessionsBetween(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'sessions',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'timestamp DESC',
    );
    return rows.map(BrushSession.fromMap).toList();
  }

  Future<BrushSession?> latestSession() async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'sessions',
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BrushSession.fromMap(rows.first);
  }

  Future<List<WeeklyStat>> fetchWeeklyStats(DateTime now) async {
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final start = endOfToday.subtract(const Duration(days: 6));
    final sessions = await fetchSessionsBetween(start, endOfToday);
    final Map<String, List<BrushSession>> byDay = {};

    for (final session in sessions) {
      final key = _dateKey(session.timestamp);
      byDay.putIfAbsent(key, () => []).add(session);
    }

    final List<WeeklyStat> stats = [];
    for (int i = 0; i < 7; i += 1) {
      final date = start.add(Duration(days: i));
      final key = _dateKey(date);
      final sessionsForDay = byDay[key] ?? [];
      final minutes = sessionsForDay.fold<double>(
        0,
        (sum, session) => sum + (session.durationSeconds / 60.0),
      );
      stats.add(
        WeeklyStat(
          day: _weekdayLabel(date.weekday),
          completed: sessionsForDay.isNotEmpty,
          minutes: minutes,
        ),
      );
    }

    return stats;
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '';
    }
  }
}
