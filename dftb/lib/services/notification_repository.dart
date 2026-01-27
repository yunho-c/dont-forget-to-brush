import 'package:sqflite/sqflite.dart';

import '../models/notification_models.dart';
import 'database_service.dart';

class NotificationRepository {
  NotificationRepository(this._databaseService);

  final DatabaseService _databaseService;

  Future<void> savePlan(NotificationPlan plan) async {
    final db = await _databaseService.database;
    await db.transaction((txn) async {
      await txn.update(
        'notification_schedules',
        {'status': NotificationScheduleStatus.canceled.storageValue},
        where: 'status = ?',
        whereArgs: [NotificationScheduleStatus.scheduled.storageValue],
      );
      await txn.insert(
        'bedtime_windows',
        plan.window.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      final batch = txn.batch();
      for (final schedule in plan.schedules) {
        batch.insert(
          'notification_schedules',
          schedule.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> addDelivery(NotificationDelivery delivery) async {
    final db = await _databaseService.database;
    await db.insert(
      'notification_deliveries',
      delivery.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> hasDeliveryForSchedule(String scheduleId) async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'notification_deliveries',
      columns: ['id'],
      where: 'schedule_id = ?',
      whereArgs: [scheduleId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> addVerificationAttempt(VerificationAttempt attempt) async {
    final db = await _databaseService.database;
    await db.insert(
      'verification_attempts',
      attempt.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertSchedule(NotificationSchedule schedule) async {
    final db = await _databaseService.database;
    await db.insert(
      'notification_schedules',
      schedule.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertAlarmState(AlarmState state) async {
    final db = await _databaseService.database;
    await db.insert(
      'alarm_states',
      state.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<AlarmState?> fetchAlarmState(String windowId) async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'alarm_states',
      where: 'window_id = ?',
      whereArgs: [windowId],
      orderBy: 'last_changed_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AlarmState.fromMap(rows.first);
  }

  Future<void> clearAlarmState(String windowId) async {
    final db = await _databaseService.database;
    await db.delete(
      'alarm_states',
      where: 'window_id = ?',
      whereArgs: [windowId],
    );
  }

  Future<void> clearAll() async {
    final db = await _databaseService.database;
    await db.delete('notification_schedules');
    await db.delete('notification_deliveries');
    await db.delete('bedtime_windows');
    await db.delete('verification_attempts');
    await db.delete('alarm_states');
  }

  Future<List<NotificationSchedule>> fetchRecentSchedules({
    int? limit = 12,
  }) async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'notification_schedules',
      orderBy: 'scheduled_at DESC',
      limit: limit,
    );
    return rows.map(NotificationSchedule.fromMap).toList();
  }

  Future<List<VerificationAttempt>> fetchRecentVerificationAttempts({
    int? limit = 12,
  }) async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'verification_attempts',
      orderBy: 'started_at DESC',
      limit: limit,
    );
    return rows.map(VerificationAttempt.fromMap).toList();
  }

  Future<List<NotificationDeliveryView>> fetchRecentDeliveryViews({
    int? limit = 12,
  }) async {
    final db = await _databaseService.database;
    final sql = StringBuffer('''
      SELECT d.*, s.type AS schedule_type
      FROM notification_deliveries d
      LEFT JOIN notification_schedules s ON s.id = d.schedule_id
      ORDER BY d.delivered_at DESC
    ''');
    final args = <Object?>[];
    if (limit != null) {
      sql.write(' LIMIT ?');
      args.add(limit);
    }
    final rows = await db.rawQuery(sql.toString(), args);
    return rows.map(NotificationDeliveryView.fromMap).toList();
  }

  Future<BedtimeWindow?> fetchLatestWindow() async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'bedtime_windows',
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BedtimeWindow.fromMap(rows.first);
  }
}
