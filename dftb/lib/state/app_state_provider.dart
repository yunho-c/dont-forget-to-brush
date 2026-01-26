import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/settings_store.dart';
import 'app_state.dart';

final settingsStoreProvider = Provider<SettingsStore>((ref) {
  return SettingsStore();
});

final appStateProvider = ChangeNotifierProvider<AppState>((ref) {
  final state = AppState(ref.read(settingsStoreProvider));
  state.load();
  ref.onDispose(state.dispose);
  return state;
});
