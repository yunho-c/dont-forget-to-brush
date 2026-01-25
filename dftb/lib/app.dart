import 'package:flutter/material.dart';

import 'services/settings_store.dart';
import 'state/app_state.dart';
import 'state/app_state_scope.dart';
import 'theme/app_theme.dart';
import 'ui/screens/home_shell.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/widgets/app_background.dart';

class DftbApp extends StatefulWidget {
  const DftbApp({super.key});

  @override
  State<DftbApp> createState() => _DftbAppState();
}

class _DftbAppState extends State<DftbApp> {
  late final AppState _state;

  @override
  void initState() {
    super.initState();
    _state = AppState(SettingsStore());
    _state.load();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "Don't Forget to Brush",
          theme: AppTheme.dark(),
          home: AppStateScope(
            notifier: _state,
            child: _state.isReady
                ? (_state.settings.isOnboarded
                      ? const HomeShell()
                      : const OnboardingScreen())
                : const _SplashScreen(),
          ),
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AppBackground(child: Center(child: CircularProgressIndicator())),
    );
  }
}
