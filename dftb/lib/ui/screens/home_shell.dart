import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class _HomeShellState extends ConsumerState<HomeShell> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);

    return Scaffold(
      body: AppBackground(
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
              method: state.settings.verificationMethod,
              onSuccess: () => unawaited(state.markBrushed()),
              onDismiss: state.closeAlarm,
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
