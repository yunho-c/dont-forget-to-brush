import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/weekly_stat.dart';
import '../services/database_service.dart';
import '../services/notification_repository.dart';
import '../services/notification_scheduler.dart';
import '../services/session_repository.dart';
import '../services/settings_store.dart';
import '../services/tag_repository.dart';
import '../services/tag_scanner.dart';
import 'app_state.dart';

final settingsStoreProvider = Provider<SettingsStore>((ref) {
  return SettingsStore();
});

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(ref.read(databaseServiceProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.read(databaseServiceProvider));
});

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return NotificationScheduler();
});

final tagRepositoryProvider = Provider<TagRepository>((ref) {
  return TagRepository();
});

final tagScannerProvider = Provider<TagScanner>((ref) {
  return TagScanner();
});

final appStateProvider = ChangeNotifierProvider<AppState>((ref) {
  final state = AppState(
    ref.read(settingsStoreProvider),
    ref.read(sessionRepositoryProvider),
    ref.read(notificationRepositoryProvider),
    ref.read(notificationSchedulerProvider),
    ref.read(tagRepositoryProvider),
    ref.read(tagScannerProvider),
  );
  state.load();
  ref.onDispose(state.dispose);
  return state;
});

final weeklyStatsProvider = FutureProvider<List<WeeklyStat>>((ref) async {
  ref.watch(appStateProvider);
  final repo = ref.read(sessionRepositoryProvider);
  return repo.fetchWeeklyStats(DateTime.now());
});
