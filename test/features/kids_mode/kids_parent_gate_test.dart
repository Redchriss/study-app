import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyapp/features/kids_mode/presentation/widgets/kids_parent_gate.dart';

void main() {
  group('KidsParentGateChallenge', () {
    test('answer is the sum and validation is exact', () {
      const c = KidsParentGateChallenge(7, 5);
      expect(c.answer, 12);
      expect(c.question, 'What is 7 + 5?');
      expect(c.isCorrect('12'), isTrue);
      expect(c.isCorrect(' 12 '), isTrue);
      expect(c.isCorrect('13'), isFalse);
      expect(c.isCorrect('abc'), isFalse);
    });

    test('random challenge uses non-trivial operands', () {
      final c = KidsParentGateChallenge.random(Random(1));
      expect(c.a, greaterThanOrEqualTo(6));
      expect(c.b, greaterThanOrEqualTo(4));
    });
  });

  testWidgets('parent gate returns true only on correct answer',
      (tester) async {
    late bool result;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async => result = await showKidsParentGate(context),
            child: const Text('open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Ask a grown-up'), findsOneWidget);

    // Wrong answer keeps the gate open.
    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Ask a grown-up'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    // Read the displayed question and answer correctly.
    final questionText = tester
        .widgetList<Text>(find.textContaining('What is '))
        .first
        .data!;
    final parts = questionText
        .replaceAll('What is ', '')
        .replaceAll('?', '')
        .split(' + ');
    final sum = int.parse(parts[0]) + int.parse(parts[1].trim());
    await tester.enterText(find.byType(TextField), '$sum');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Ask a grown-up'), findsNothing);
    expect(result, isTrue);
  });
}
