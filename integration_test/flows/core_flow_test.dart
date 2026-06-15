/// Core app flow tests — verifies main screens load after login.
/// Run: flutter test integration_test/flows/core_flow_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:studyapp/main.dart' as app;

import '../robots/auth_robot.dart';
import '../robots/feed_robot.dart';
import '../robots/study_robot.dart';
import '../robots/dashboard_robot.dart';
import '../setup/test_environment.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Core App Flow — after login', () {
    testWidgets('1. Feed screen loads with search bar and sort tabs',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Login first
      final auth = AuthRobot(tester);
      await auth.enterUsername(kTestUsername);
      await auth.enterPassword(kTestPassword);
      await auth.tapLogin();
      await tester.pumpAndSettle(const Duration(seconds: 20));

      // Verify feed
      final feed = FeedRobot(tester);
      feed.verifyFeedLoaded();
      feed.verifySearchBarVisible();
      feed.verifyTabsVisible();
    });

    testWidgets('2. Study Hub loads with Materials, Quizzes, Tools tabs',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final auth = AuthRobot(tester);
      await auth.enterUsername(kTestUsername);
      await auth.enterPassword(kTestPassword);
      await auth.tapLogin();
      await tester.pumpAndSettle(const Duration(seconds: 20));

      final study = StudyRobot(tester);
      await study.goToStudy();
      study.verifyStudyHubLoaded();
    });

    testWidgets('3. Study Hub Tools tab shows Scanner', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final auth = AuthRobot(tester);
      await auth.enterUsername(kTestUsername);
      await auth.enterPassword(kTestPassword);
      await auth.tapLogin();
      await tester.pumpAndSettle(const Duration(seconds: 20));

      final study = StudyRobot(tester);
      await study.goToStudy();
      await study.tapToolsTab();
      study.verifyScannerToolVisible();
    });

    testWidgets('4. Dashboard shows greeting and quick actions',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final auth = AuthRobot(tester);
      await auth.enterUsername(kTestUsername);
      await auth.enterPassword(kTestPassword);
      await auth.tapLogin();
      await tester.pumpAndSettle(const Duration(seconds: 20));

      final dashboard = DashboardRobot(tester);
      await dashboard.goToDashboard();
      dashboard.verifyDashboardLoaded();
      dashboard.verifyQuickActionsVisible();
    });
  });
}
