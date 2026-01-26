import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/weekly_stat.dart';
import '../services/database_service.dart';
import '../services/notification_scheduler.dart';
import '../services/session_repository.dart';
import '../services/settings_store.dart';
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

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  final scheduler = NotificationScheduler();
  unawaited(scheduler.initialize());
  return scheduler;
});

final appStateProvider = ChangeNotifierProvider<AppState>((ref) {
  final state = AppState(
    ref.read(settingsStoreProvider),
    ref.read(sessionRepositoryProvider),
    ref.read(notificationSchedulerProvider),
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
