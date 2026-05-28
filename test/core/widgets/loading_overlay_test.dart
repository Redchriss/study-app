import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyapp/core/widgets/loading_overlay.dart';

void main() {
  group('LoadingOverlay Widget Tests', () {
    testWidgets('should show loading indicator when visible',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingOverlay(
              visible: true,
              message: 'Loading...',
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('should not show when visible is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingOverlay(
              visible: false,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should show message when provided',
        (WidgetTester tester) async {
      const testMessage = 'Please wait...';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingOverlay(
              visible: true,
              message: testMessage,
            ),
          ),
        ),
      );

      expect(find.text(testMessage), findsOneWidget);
    });
  });

  group('LoadingBuilder Widget Tests', () {
    testWidgets('should show child when not loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingBuilder(
              loading: false,
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should show overlay when loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingBuilder(
              loading: true,
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
