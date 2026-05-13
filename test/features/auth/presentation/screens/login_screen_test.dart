import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studyapp/features/auth/presentation/screens/login_screen.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    Widget createApp({List<GoRoute> extraRoutes = const []}) {
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
          ...extraRoutes,
        ],
      );
      return ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    testWidgets('should display login form', (WidgetTester tester) async {
      await tester.pumpWidget(createApp());

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Log in to continue studying'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('should show password visibility toggle', (WidgetTester tester) async {
      await tester.pumpWidget(createApp());

      final passwordField = find.byType(TextFormField).last;
      await tester.tap(passwordField);
      await tester.pump();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('should validate empty fields', (WidgetTester tester) async {
      await tester.pumpWidget(createApp());

      final loginButton = find.text('Log In');
      await tester.tap(loginButton);
      await tester.pump();

      expect(find.text('Required'), findsNWidgets(2));
    });

    testWidgets('should navigate to register on tap', (WidgetTester tester) async {
      await tester.pumpWidget(createApp(
        extraRoutes: [
          GoRoute(path: '/register', builder: (_, __) => const Scaffold(body: Text('Register Page'))),
        ],
      ));

      await tester.tap(find.text("Don't have an account? Sign up"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Register Page'), findsOneWidget);
    });
  });
}
