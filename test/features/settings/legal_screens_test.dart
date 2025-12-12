import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:waitless/features/settings/screens/privacy_policy_screen.dart';
import 'package:waitless/features/settings/screens/terms_of_service_screen.dart';
import 'package:waitless/core/theme/app_theme.dart';

void main() {
  group('PrivacyPolicyScreen', () {
    testWidgets('displays title in AppBar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const PrivacyPolicyScreen(),
          ),
        ),
      );
      await tester.pump();

      // Check AppBar title
      expect(find.widgetWithText(AppBar, 'Privacy Policy'), findsOneWidget);
    });

    testWidgets('displays Introduction section', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const PrivacyPolicyScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Introduction'), findsOneWidget);
    });

    testWidgets('is scrollable', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const PrivacyPolicyScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });

  group('TermsOfServiceScreen', () {
    testWidgets('displays title in AppBar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const TermsOfServiceScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.widgetWithText(AppBar, 'Terms of Service'), findsOneWidget);
    });

    testWidgets('displays Acceptance of Terms section', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const TermsOfServiceScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('1. Acceptance of Terms'), findsOneWidget);
    });

    testWidgets('is scrollable', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const TermsOfServiceScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
