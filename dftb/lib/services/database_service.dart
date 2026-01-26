import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    final dbPath = await getDatabasesPath();
    final filePath = path.join(dbPath, 'dftb.db');
    _database = await openDatabase(
      filePath,
      version: 2,
      onCreate: _createSchema,
      onUpgrade: _upgradeSchema,
    );
    return _database!;
  }

  Future<void> _createSchema(Database db, int version) async {
    await _createSessionsTable(db);
    await _createNotificationTables(db);
  }

  Future<void> _upgradeSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createNotificationTables(db);
    }
  }

  Future<void> _createSessionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sessions (
        id TEXT PRIMARY KEY,
        timestamp TEXT NOT NULL,
        method TEXT NOT NULL,
        was_late INTEGER NOT NULL DEFAULT 0,
        duration_seconds INTEGER NOT NULL DEFAULT 120
      )
    ''');
  }

  Future<void> _createNotificationTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bedtime_windows (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        start_at TEXT NOT NULL,
        end_at TEXT NOT NULL,
        mode TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notification_schedules (
        id TEXT PRIMARY KEY,
        window_id TEXT NOT NULL,
        type TEXT NOT NULL,
        scheduled_at TEXT NOT NULL,
        payload TEXT,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notification_deliveries (
        id TEXT PRIMARY KEY,
        schedule_id TEXT NOT NULL,
        delivered_at TEXT NOT NULL,
        delivery_status TEXT NOT NULL,
        platform_id TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS verification_attempts (
        id TEXT PRIMARY KEY,
        window_id TEXT NOT NULL,
        method TEXT NOT NULL,
        started_at TEXT NOT NULL,
        completed_at TEXT,
        result TEXT NOT NULL,
        failure_reason TEXT,
        metadata TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS alarm_states (
        id TEXT PRIMARY KEY,
        window_id TEXT NOT NULL,
        status TEXT NOT NULL,
        snooze_count INTEGER NOT NULL DEFAULT 0,
        last_changed_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_notification_schedules_window
      ON notification_schedules(window_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_notification_schedules_time
      ON notification_schedules(scheduled_at)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_notification_deliveries_schedule
      ON notification_deliveries(schedule_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_verification_attempts_window
      ON verification_attempts(window_id)
    ''');
  }
}
