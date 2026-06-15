import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// DashboardRobot — interacts with the Dashboard screen.
class DashboardRobot {
  final WidgetTester tester;
  const DashboardRobot(this.tester);

  Finder get _dashboardTab =>
      find.byWidgetPredicate((w) => w is Text && w.data == 'Dashboard');

  Finder get _aiTutorButton => find.byWidgetPredicate((w) =>
      w is Text && w.data?.toLowerCase().contains('ai tutor') == true);

  Finder get _creditsWidget => find.byWidgetPredicate((w) =>
      w is Text && w.data?.toLowerCase().contains('credit') == true);

  Future<void> goToDashboard() async {
    await tester.tap(_dashboardTab);
    await tester.pumpAndSettle(const Duration(seconds: 10));
  }

  void verifyDashboardLoaded() {
    // Dashboard has greeting text
    expect(
      find.byWidgetPredicate((w) =>
          w is Text &&
          (w.data?.contains('Good morning') == true ||
           w.data?.contains('Good afternoon') == true ||
           w.data?.contains('Good evening') == true)),
      findsWidgets,
      reason: 'Dashboard should show time-based greeting',
    );
  }

  void verifyCreditsVisible() {
    expect(_creditsWidget, findsWidgets,
        reason: 'AI credits should be shown on dashboard');
  }

  void verifyQuickActionsVisible() {
    expect(
      find.byWidgetPredicate(
          (w) => w is Text && w.data?.toLowerCase() == 'quiz'),
      findsWidgets,
      reason: 'Quick action tiles should be visible',
    );
  }
}
