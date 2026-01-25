import 'package:flutter/material.dart';

import '../../state/app_state_scope.dart';
import '../overlays/verification_overlay.dart';
import '../widgets/app_background.dart';
import '../widgets/bottom_nav.dart';
import 'dashboard_screen.dart';
import 'insights_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return Scaffold(
      body: AppBackground(
        showLine: _tabIndex == 0,
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
              onSuccess: state.markBrushed,
              onDismiss: state.closeAlarm,
            ),
          ],
        ),
      ),
    );
  }
}
