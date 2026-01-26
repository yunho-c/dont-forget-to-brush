import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import 'state/app_state_provider.dart';
import 'theme/app_theme.dart';
import 'ui/screens/home_shell.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/widgets/app_background.dart';

class DftbApp extends ConsumerWidget {
  const DftbApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    return shadcn.ShadcnApp(
      debugShowCheckedModeBanner: false,
      title: "Don't Forget to Brush",
      theme: AppTheme.shadcnDark(),
      materialTheme: AppTheme.materialDark(),
      home: state.isReady
          ? (state.settings.isOnboarded
                ? const HomeShell()
                : const OnboardingScreen())
          : const _SplashScreen(),
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
