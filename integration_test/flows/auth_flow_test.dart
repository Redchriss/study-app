/// Auth flow integration tests.
/// Run: flutter test integration_test/flows/auth_flow_test.dart
///
/// These tests boot the REAL app, tap real buttons, and talk to the
/// live backend. They catch what unit tests cannot.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:studyapp/main.dart' as app;

import '../robots/auth_robot.dart';
import '../robots/home_robot.dart';
import '../setup/test_environment.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth Flow — Login', () {
    testWidgets(
      '1. Wrong password shows error on login screen — screen does NOT change',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        final auth = AuthRobot(tester);
        final home = HomeRobot(tester);

        // Enter wrong credentials
        await auth.enterUsername(kTestUsername);
        await auth.enterPassword('wrongpassword_xyz');
        await auth.tapLogin();

        // Wait for response
        await tester.pumpAndSettle(const Duration(seconds: 15));

        // MUST still be on login screen — no blue screen, no redirect
        auth.verifyOnLoginScreen();
        auth.verifyErrorVisible();

        // MUST NOT be on home screen
        home.verifyNotOnAuthScreen(); // inverted — login btn should still exist
      },
    );

    testWidgets(
      '2. Correct password logs in and shows app',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        final auth = AuthRobot(tester);
        final home = HomeRobot(tester);

        await auth.enterUsername(kTestUsername);
        await auth.enterPassword(kTestPassword);
        await auth.tapLogin();

        // Wait for full auth + navigation (backend call can take ~5s)
        await tester.pumpAndSettle(const Duration(seconds: 20));

        // Must be inside the app now
        home.verifyAppLoaded();
        home.verifyFeedTabVisible();
        auth.verifyNotOnLoginScreen();
      },
    );

    testWidgets(
      '3. Login button shows spinner while waiting — screen stays put',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        final auth = AuthRobot(tester);

        await auth.enterUsername(kTestUsername);
        await auth.enterPassword(kTestPassword);
        await auth.tapLogin();

        // Immediately after tap — spinner should appear, still on login screen
        await tester.pump(const Duration(milliseconds: 100));
        auth.verifySpinnerVisible();
        auth.verifyOnLoginScreen();
      },
    );
  });
}
