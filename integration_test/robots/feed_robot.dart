import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// FeedRobot — interacts with the Circles/Feed screen.
class FeedRobot {
  final WidgetTester tester;
  const FeedRobot(this.tester);

  Finder get _feedTab =>
      find.byWidgetPredicate((w) => w is Text && w.data == 'Feed');

  Finder get _searchBar => find.byWidgetPredicate((w) =>
      w is TextField &&
      w.decoration?.hintText?.toLowerCase().contains('search') == true);

  Future<void> goToFeed() async {
    await tester.tap(_feedTab);
    await tester.pumpAndSettle(const Duration(seconds: 10));
  }

  void verifyFeedLoaded() {
    expect(find.byType(ListView), findsWidgets,
        reason: 'Feed should show a list');
  }

  void verifySearchBarVisible() {
    expect(_searchBar, findsOneWidget,
        reason: 'Search bar should be at top of feed');
  }

  void verifyTabsVisible() {
    expect(find.byType(TabBar), findsWidgets,
        reason: 'Sort tabs (Best/Hot/New) should be visible');
  }
}
