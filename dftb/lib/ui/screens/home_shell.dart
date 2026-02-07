import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import '../../state/app_state_provider.dart';
import '../overlays/verification_overlay.dart';
import '../widgets/app_background.dart';
import '../widgets/bottom_nav.dart';
import 'dashboard_screen.dart';
import 'insights_screen.dart';
import 'settings_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(appStateProvider).handleAppResumed());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);

    return shadcn.Scaffold(
      child: AppBackground(
        child: Stack(
          children: [
            SafeArea(
              child: IndexedStack(
                index: _tabIndex,
                children: const [
                  DashboardScreen(),
                  InsightsScreen(),
                  SettingsScreen(),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: BottomNav(
                currentIndex: _tabIndex,
                onTap: (index) => setState(() => _tabIndex = index),
              ),
            ),
            VerificationOverlay(
              isOpen: state.isAlarmOpen,
              isAlarmMode: state.isAlarmMode,
              routinePhase: state.routinePhase,
              method: state.settings.verificationMethod,
              alarmTone: state.settings.alarmTone,
              supportsSnooze: state.supportsSnooze,
              canSnooze: state.canSnooze,
              snoozeLabel: state.snoozeLabel,
              isDeveloperMode: state.isDeveloperMode,
              activeTags: state.activeTags,
              onSuccess: () => unawaited(state.markBrushed()),
              onDismiss: state.closeAlarm,
              onSnooze: () => unawaited(state.snoozeAlarm()),
              onTagScan: state.scanAndVerifyTag,
              onDebugMatchTag: (tagId) => state.debugMatchTag(tagId: tagId),
              onDebugWrongTag: state.debugWrongTag,
              onFailure: (reason) =>
                  unawaited(state.recordVerificationFailure(reason)),
              onCancel: () => unawaited(state.recordVerificationCanceled()),
            ),
          ],
        ),
      ),
    );
  }
}
