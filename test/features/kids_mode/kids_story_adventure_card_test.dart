import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyapp/features/kids_mode/presentation/widgets/kids_story_adventure_card.dart';

void main() {
  group('KidsStoryAdventure.parseStory', () {
    test('parses a Map payload', () {
      final story = KidsStoryAdventure.parseStory({
        'intro': 'Help the seed grow!',
        'choices': [
          {'label': 'Water it', 'outcome': 'It sprouts!'},
          {'label': 'Wait'},
        ],
      });
      expect(story, isNotNull);
      expect(story!.intro, 'Help the seed grow!');
      expect(story.choices.length, 2);
      expect(story.choices.first.outcome, 'It sprouts!');
    });

    test('parses a JSON string payload', () {
      final story = KidsStoryAdventure.parseStory(
          '{"intro":"Go on an adventure","choices":[{"label":"Start"}]}');
      expect(story, isNotNull);
      expect(story!.choices.single.label, 'Start');
    });

    test('returns null for null, malformed, or empty data', () {
      expect(KidsStoryAdventure.parseStory(null), isNull);
      expect(KidsStoryAdventure.parseStory('not json'), isNull);
      expect(KidsStoryAdventure.parseStory({'intro': ''}), isNull);
      expect(
          KidsStoryAdventure.parseStory({'intro': 'Hi', 'choices': []}), isNull);
    });
  });

  testWidgets('KidsStoryAdventureCard renders intro and choices, reveals outcome',
      (tester) async {
    final story = KidsStoryAdventure.parseStory({
      'intro': 'A mango adventure begins!',
      'choices': [
        {'label': 'Share the mango', 'outcome': 'Everyone is happy!'},
      ],
    })!;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: KidsStoryAdventureCard(story: story)),
    ));

    expect(find.text('A mango adventure begins!'), findsOneWidget);
    expect(find.text('Share the mango'), findsOneWidget);
    // Outcome only after the child taps the choice.
    expect(find.text('Everyone is happy!'), findsNothing);
    await tester.tap(find.text('Share the mango'));
    await tester.pumpAndSettle();
    expect(find.text('Everyone is happy!'), findsOneWidget);
  });
}
