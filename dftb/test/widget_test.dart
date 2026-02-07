// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import 'package:dftb/theme/app_theme.dart';
import 'package:dftb/ui/screens/onboarding_screen.dart';

void main() {
  testWidgets('renders onboarding setup screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: shadcn.ShadcnApp(
          theme: AppTheme.shadcnDark(),
          materialTheme: AppTheme.materialDark(),
          home: const OnboardingScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text("Let's set you up."), findsOneWidget);
  });
}
