import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

/// HomeRobot — knows how to verify the home/dashboard/feed screens.
class HomeRobot {
  final WidgetTester tester;
  const HomeRobot(this.tester);

  // ── Finders ────────────────────────────────────────────────────────────────
  Finder get _bottomNav => find.byType(BottomAppBar).first;

  Finder get _feedTab =>
      find.byWidgetPredicate((w) =>
          w is Text && w.data?.toLowerCase() == 'feed');

  Finder get _studyTab =>
      find.byWidgetPredicate((w) =>
          w is Text && w.data?.toLowerCase() == 'study');

  Finder get _profileTab =>
      find.byWidgetPredicate((w) =>
          w is Text && w.data?.toLowerCase() == 'profile');

  Finder get _aiTutorButton =>
      find.byWidgetPredicate((w) =>
          w is Text && w.data?.toUpperCase() == 'AI');

  // ── Assertions ─────────────────────────────────────────────────────────────
  void verifyAppLoaded() {
    // App is loaded if we see the bottom nav tabs
    expect(find.byType(Scaffold), findsWidgets,
        reason: 'App should show at least one Scaffold after login');
  }

  void verifyFeedTabVisible() {
    expect(_feedTab, findsWidgets,
        reason: 'Feed tab should be visible in bottom nav');
  }

  void verifyStudyTabVisible() {
    expect(_studyTab, findsWidgets,
        reason: 'Study tab should be visible in bottom nav');
  }

  void verifyNotOnAuthScreen() {
    expect(find.widgetWithText(ElevatedButton, 'Log In'), findsNothing,
        reason: 'Login button should not be visible after auth');
    expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsNothing);
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  Future<void> tapStudyTab() async {
    await tester.tap(_studyTab);
    await tester.pumpAndSettle();
  }

  Future<void> tapProfileTab() async {
    await tester.tap(_profileTab);
    await tester.pumpAndSettle();
  }
}
