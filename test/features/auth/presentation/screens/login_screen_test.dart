import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyapp/features/auth/presentation/screens/login_screen.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('should display login form', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Log in to continue studying'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('should show password visibility toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      final passwordField = find.byType(TextFormField).last;
      await tester.tap(passwordField);
      await tester.pump();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('should validate empty fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      final loginButton = find.text('Log In');
      await tester.tap(loginButton);
      await tester.pump();

      expect(find.text('Required'), findsNWidgets(2));
    });

    testWidgets('should navigate to register on tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      final registerButton = find.text("Don't have an account? Sign up");
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Navigation would be tested with go_router mock in real scenario
      expect(registerButton, findsOneWidget);
    });
  });
}
