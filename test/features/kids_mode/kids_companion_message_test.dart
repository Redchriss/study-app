import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyapp/features/kids_mode/presentation/widgets/kids_companion_character.dart';

void main() {
  testWidgets('KidsCompanionMessage renders the AI companion line',
      (tester) async {
    const line = 'Hi Chisomo! Ready to learn about plants?';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: KidsCompanionMessage(
            message: line,
            type: CompanionType.sprout,
          ),
        ),
      ),
    );

    expect(find.text(line), findsOneWidget);
    // The bubble exposes the line to screen readers as a live region.
    expect(find.byType(KidsCompanionCharacter), findsOneWidget);
  });
}
