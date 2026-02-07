import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dftb/models/app_mode.dart';
import 'package:dftb/models/notification_models.dart';
import 'package:dftb/services/database_service.dart';
import 'package:dftb/services/notification_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('savePlan persists window and schedules', () async {
    final dbService = DatabaseService();
    final repo = NotificationRepository(dbService);

    await repo.clearAll();

    final window = BedtimeWindow(
      date: DateTime(2026, 1, 26),
      startAt: DateTime(2026, 1, 26, 22),
      endAt: DateTime(2026, 1, 27, 1),
      mode: AppMode.accountability,
      createdAt: DateTime(2026, 1, 26, 12),
    );
    final schedules = [
      NotificationSchedule(
        windowId: window.id,
        type: NotificationScheduleType.reminder,
        scheduledAt: DateTime(2026, 1, 26, 22),
        status: NotificationScheduleStatus.scheduled,
        payload: {'title': 'Brush now'},
      ),
      NotificationSchedule(
        windowId: window.id,
        type: NotificationScheduleType.alarm,
        scheduledAt: DateTime(2026, 1, 27, 1),
        status: NotificationScheduleStatus.scheduled,
        payload: {'title': 'Brush required'},
      ),
    ];

    await repo.savePlan(NotificationPlan(window: window, schedules: schedules));

    final latestWindow = await repo.fetchLatestWindow();
    expect(latestWindow?.id, window.id);

    final recentSchedules = await repo.fetchRecentSchedules(limit: 10);
    expect(recentSchedules.length, 2);
    expect(
      recentSchedules.every((schedule) => schedule.windowId == window.id),
      isTrue,
    );
  });
}
