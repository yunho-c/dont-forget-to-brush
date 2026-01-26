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

  Future<void> addVerificationAttempt(VerificationAttempt attempt) async {
    final db = await _databaseService.database;
    await db.insert(
      'verification_attempts',
      attempt.toMap(),
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

  Future<void> clearAll() async {
    final db = await _databaseService.database;
    await db.delete('notification_schedules');
    await db.delete('notification_deliveries');
    await db.delete('bedtime_windows');
    await db.delete('verification_attempts');
    await db.delete('alarm_states');
  }
}
