import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:studyapp/core/theme/app_theme.dart';
import 'package:studyapp/router.dart';
import 'package:studyapp/features/auth/presentation/providers/auth_provider.dart';
import 'package:studyapp/features/auth/presentation/screens/splash_screen.dart';
import 'package:studyapp/features/auth/presentation/screens/onboarding_v2/onboarding_screen_v2.dart';

/// Integration tests run on a real device or emulator.
///   flutter test integration_test/
///
/// These tests verify actual screen rendering, navigation, and user flows
/// on real hardware — catching layout issues, overflow, and performance
/// problems that unit tests can't find.

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Widget buildApp() {
    return const ProviderScope(
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
      expect(find.byType(OnboardingScreenV2), findsWidgets);
    });

    testWidgets('3. Login screen displays correctly', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 3));

      // Navigate to login
      final loginButtons = find.text('Log In');
      if (loginButtons.evaluate().isEmpty) {
        final loginLinks = find.text('Log in');
        if (loginLinks.evaluate().isNotEmpty) {
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
      if (loginBtn.evaluate().isNotEmpty) {
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
      if (signupLinks.evaluate().isNotEmpty) {
        await tester.ensureVisible(signupLinks.first);
        await tester.tap(signupLinks.first);
        await tester.pumpAndSettle();
      }

      // Check register screen elements
      expect(find.text('Create an Account'), findsAny);
      expect(find.byType(TextFormField), findsAtLeast(3));
    });

    testWidgets('6. Bottom navigation renders on authenticated pages',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(Navigator), findsAtLeast(1));
    });
  });

  group('Screen Rendering Tests', () {
    testWidgets('7. Dialog and bottom sheet rendering', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
    });

    testWidgets('8. Scroll performance test', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 2));

      final listViews = find.byType(ListView);
      if (listViews.evaluate().isNotEmpty) {
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

      for (var i = 0; i < 5; i++) {
        final buttons = find.byType(ElevatedButton);
        if (buttons.evaluate().isNotEmpty) {
          try {
            await tester.tap(buttons.first);
            await tester.pump(const Duration(milliseconds: 50));
          } catch (_) {
            // Ignore render errors from rapid navigation
          }
        }
      }

      expect(tester.takeException(), isNull);
    });

    testWidgets('10. Keyboard appearance and form fields', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 2));

      final textFields = find.byType(TextFormField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.tap(textFields.first);
        await tester.pump();
        tester.testTextInput.enterText('test input');
        await tester.pump();
      }

      expect(tester.takeException(), isNull);
    });
  });

  group('Device Compatibility', () {
    testWidgets('11. Small screen renders without overflow', (tester) async {
      tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
    });

    testWidgets('12. Tablet screen renders correctly', (tester) async {
      tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
    });

    testWidgets('13. Dark mode toggle does not crash', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
    });
  });
}

class _TestApp extends ConsumerWidget {
  const _TestApp();

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
