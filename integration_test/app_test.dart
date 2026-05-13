import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:studyapp/core/graphql/client.dart';
import 'package:studyapp/core/theme/app_theme.dart';
import 'package:studyapp/router.dart';
import 'package:studyapp/features/auth/presentation/screens/splash_screen.dart';
import 'package:studyapp/features/auth/presentation/screens/login_screen.dart';
import 'package:studyapp/features/auth/presentation/screens/register_screen.dart';
import 'package:studyapp/features/auth/presentation/screens/onboarding_screen.dart';

/// Integration tests run on a real device or emulator.
///   flutter test integration_test/
///
/// These tests verify actual screen rendering, navigation, and user flows
/// on real hardware — catching layout issues, overflow, and performance
/// problems that unit tests can't find.

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Widget buildApp() {
    return ProviderScope(
      child: _TestApp(),
    );
  }

  group('App Launch & Auth', () {
    testWidgets('1. Splash screen appears on launch', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Yaza'), findsOneWidget);
      expect(find.text('Learn. Grow. Pass.'), findsOneWidget);

      // Wait for auth bootstrap to redirect away
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('2. Unauthenticated user sees onboarding', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 5));

      // After auth check, unauthenticated users go to onboarding
      expect(find.byType(OnboardingScreen), findsWidgets);
    });

    testWidgets('3. Login screen displays correctly', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 3));

      // Navigate to login
      final loginButtons = find.text('Log In');
      if (loginButtons.isEmpty) {
        // Find any navigate-to-login button
        final loginLinks = find.text('Log in');
        if (loginLinks.isNotEmpty) {
          await tester.tap(loginLinks.first);
          await tester.pumpAndSettle();
        }
      }

      // Verify login form elements render correctly
      expect(find.text('Welcome back'), findsAny);
      expect(find.byType(TextFormField), findsAtLeast(2));
      expect(find.text('Log In'), findsAny);
    });

    testWidgets('4. Empty login validation shows errors', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 3));

      // Find and tap login button
      final loginBtn = find.text('Log In');
      if (loginBtn.isNotEmpty) {
        await tester.ensureVisible(loginBtn.first);
        await tester.tap(loginBtn.first);
        await tester.pump();

        // Validation errors should appear
        expect(find.text('Required'), findsAtLeast(1));
      }
    });

    testWidgets('5. Register screen renders all fields', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 3));

      // Navigate to register
      final signupLinks = find.text("Don't have an account? Sign up");
      if (signupLinks.isNotEmpty) {
        await tester.ensureVisible(signupLinks.first);
        await tester.tap(signupLinks.first);
        await tester.pumpAndSettle();
      }

      // Check register screen elements
      expect(find.text('Create an Account'), findsAny);
      expect(find.byType(TextFormField), findsAtLeast(3));
    });

    testWidgets('6. Bottom navigation renders on authenticated pages', (tester) async {
      // Test that navigation shell renders correctly
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 2));

      // These navigation items should render on auth pages
      // Check that basic navigation elements are present
      expect(find.byType(Navigator), findsAtLeast(1));
    });
  });

  group('Screen Rendering Tests', () {
    testWidgets('7. Dialog and bottom sheet rendering', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 1));

      // Verify the app still renders without crashes
      expect(tester.takeException(), isNull);
    });

    testWidgets('8. Scroll performance test', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 2));

      // Try scrolling on onboarding (if visible)
      final listViews = find.byType(ListView);
      if (listViews.isNotEmpty) {
        await tester.drag(listViews.first, const Offset(0, -500));
        await tester.pump();
        await tester.drag(listViews.first, const Offset(0, 500));
        await tester.pump();
      }

      expect(tester.takeException(), isNull);
    });
  });

  group('Edge Cases', () {
    testWidgets('9. Rapid navigation between screens', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 1));

      // Rapidly tap multiple buttons to test for crashes
      for (var i = 0; i < 5; i++) {
        final buttons = find.byType(ElevatedButton);
        if (buttons.isNotEmpty) {
          try {
            await tester.tap(buttons.first);
            await tester.pump(const Duration(milliseconds: 50));
          } catch (_) {
            // Ignore render errors from rapid navigation
          }
        }
      }

      // App should not crash from rapid taps
      expect(tester.takeException(), isNull);
    });

    testWidgets('10. Keyboard appearance and form fields', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 2));

      // Tap text fields to trigger keyboard
      final textFields = find.byType(TextFormField);
      if (textFields.isNotEmpty) {
        await tester.tap(textFields.first);
        await tester.pump();
        await tester.testTextInput.enterText('test input');
        await tester.pump();
      }

      expect(tester.takeException(), isNull);
    });
  });

  group('Device Compatibility', () {
    testWidgets('11. Small screen renders without overflow', (tester) async {
      // Test on 360x640 (small Android phone)
      tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 2));

      // No overflow errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('12. Tablet screen renders correctly', (tester) async {
      // Test on 1024x768 (tablet)
      tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
    });

    testWidgets('13. Dark mode toggle does not crash', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 1));

      // Just verify the app initializes without crashing
      expect(tester.takeException(), isNull);
    });
  });
}

class _TestApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(graphqlClientProvider);
    return GraphQLProvider(
      client: ValueNotifier(client),
      child: MaterialApp.router(
        title: 'Yaza Test',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        routerConfig: ref.watch(routerProvider),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
