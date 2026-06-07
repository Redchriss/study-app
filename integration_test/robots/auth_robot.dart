import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// AuthRobot — knows how to interact with login and register screens.
/// Does NOT know about business logic — only taps and types.
class AuthRobot {
  final WidgetTester tester;
  const AuthRobot(this.tester);

  // ── Finders ────────────────────────────────────────────────────────────────
  Finder get _usernameField =>
      find.byWidgetPredicate((w) =>
          w is TextField &&
          (w.decoration?.labelText?.toLowerCase().contains('username') == true ||
           w.decoration?.hintText?.toLowerCase().contains('username') == true));

  Finder get _passwordField =>
      find.byWidgetPredicate((w) =>
          w is TextField &&
          (w.decoration?.labelText?.toLowerCase().contains('password') == true));

  Finder get _loginButton =>
      find.widgetWithText(ElevatedButton, 'Log In');

  Finder get _errorBanner =>
      find.byWidgetPredicate((w) =>
          w is Container &&
          w.decoration is BoxDecoration);

  Finder get _spinner =>
      find.byType(CircularProgressIndicator);

  // ── Actions ────────────────────────────────────────────────────────────────
  Future<void> enterUsername(String username) async {
    await tester.tap(_usernameField);
    await tester.enterText(_usernameField, username);
    await tester.pump();
  }

  Future<void> enterPassword(String password) async {
    await tester.tap(_passwordField);
    await tester.enterText(_passwordField, password);
    await tester.pump();
  }

  Future<void> tapLogin() async {
    await tester.tap(_loginButton);
    await tester.pump(); // start submit
  }

  Future<void> waitForAuthComplete({Duration timeout = const Duration(seconds: 30)}) async {
    await tester.pumpAndSettle(timeout);
  }

  // ── Assertions ─────────────────────────────────────────────────────────────
  void verifyOnLoginScreen() {
    expect(_loginButton, findsOneWidget,
        reason: 'Should still be on login screen');
  }

  void verifySpinnerVisible() {
    expect(_spinner, findsWidgets,
        reason: 'Spinner should show while logging in');
  }

  void verifyErrorVisible() {
    // Error text should be visible somewhere on screen
    expect(
      find.byWidgetPredicate((w) =>
          w is Text &&
          (w.data?.toLowerCase().contains('incorrect') == true ||
           w.data?.toLowerCase().contains('invalid') == true ||
           w.data?.toLowerCase().contains('wrong') == true ||
           w.data?.toLowerCase().contains('failed') == true)),
      findsWidgets,
      reason: 'Error message should be visible after wrong credentials',
    );
  }

  void verifyNotOnLoginScreen() {
    expect(_loginButton, findsNothing,
        reason: 'Login button should be gone after successful login');
  }
}
