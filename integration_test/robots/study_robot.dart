import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// StudyRobot — interacts with the Study Hub screen.
class StudyRobot {
  final WidgetTester tester;
  const StudyRobot(this.tester);

  Finder get _studyTab =>
      find.byWidgetPredicate((w) => w is Text && w.data == 'Study');

  Finder get _materialsTab =>
      find.byWidgetPredicate((w) => w is Text && w.data == 'Materials');

  Finder get _quizzesTab =>
      find.byWidgetPredicate((w) => w is Text && w.data == 'Quizzes');

  Finder get _toolsTab =>
      find.byWidgetPredicate((w) => w is Text && w.data == 'Tools');

  Future<void> goToStudy() async {
    await tester.tap(_studyTab);
    await tester.pumpAndSettle(const Duration(seconds: 10));
  }

  Future<void> tapQuizzesTab() async {
    await tester.tap(_quizzesTab);
    await tester.pumpAndSettle(const Duration(seconds: 10));
  }

  Future<void> tapToolsTab() async {
    await tester.tap(_toolsTab);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

  void verifyStudyHubLoaded() {
    expect(_materialsTab, findsWidgets,
        reason: 'Materials tab should be visible in Study Hub');
    expect(_quizzesTab, findsWidgets,
        reason: 'Quizzes tab should be visible');
    expect(_toolsTab, findsWidgets, reason: 'Tools tab should be visible');
  }

  void verifyMaterialsListVisible() {
    expect(find.byType(ListView), findsWidgets,
        reason: 'Materials list should load');
  }

  void verifyScannerToolVisible() {
    expect(
      find.byWidgetPredicate((w) =>
          w is Text &&
          w.data?.toLowerCase().contains('scanner') == true),
      findsWidgets,
      reason: 'AI Paper Solver should be in Tools tab',
    );
  }
}
