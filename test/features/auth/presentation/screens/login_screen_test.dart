import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studyapp/features/auth/presentation/providers/auth_provider.dart';
import 'package:studyapp/features/auth/presentation/screens/login_screen.dart';

class _TestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() {
    return const AuthState(isAuthenticated: false, isLoading: false);
  }

  @override
  Future<bool> login(String username, String password) async {
    state = const AuthState(
      isAuthenticated: false,
      isLoading: false,
      error: 'That username or password is incorrect.',
    );
    return false;
  }
}

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
        overrides: [
          authProvider.overrideWith(_TestAuthNotifier.new),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    testWidgets('should display login form', (WidgetTester tester) async {
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Log in to continue studying'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('should show password visibility toggle',
        (WidgetTester tester) async {
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final passwordField = find.byType(TextFormField).last;
      await tester.tap(passwordField);
      await tester.pump();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('should validate empty fields', (WidgetTester tester) async {
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Scroll down to find the button
      final loginButton = find.text('Log In');
      await tester.ensureVisible(loginButton);
      await tester.pump();
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(find.text('Enter your username'), findsAtLeastNWidgets(1));
      expect(find.text('Enter your password'), findsAtLeastNWidgets(1));
    });

    testWidgets('should show clear incorrect credentials message',
        (WidgetTester tester) async {
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.enterText(find.byType(TextFormField).first, 'wrong-user');
      await tester.enterText(find.byType(TextFormField).last, 'wrong-pass');

      final loginButton = find.text('Log In');
      await tester.ensureVisible(loginButton);
      await tester.pump();
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(
        find.text('That username or password is incorrect.'),
        findsOneWidget,
      );
    });

    testWidgets('should navigate to register on tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(createApp(
        extraRoutes: [
          GoRoute(
              path: '/register',
              builder: (_, __) => const Scaffold(body: Text('Register Page'))),
        ],
      ));

      final signUpLink = find.textContaining('Sign up', findRichText: true);
      await tester.ensureVisible(signUpLink);
      await tester.tap(signUpLink);
      await tester.pumpAndSettle();

      expect(find.text('Register Page'), findsOneWidget);
    });
  });
}
