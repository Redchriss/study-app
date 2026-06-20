import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyapp/features/materials/presentation/screens/study_pack_sheet.dart';

StudyPackData _samplePack() {
  return StudyPackData.parse({
    'lesson': [
      {'heading': 'Levers', 'body': 'A lever uses a fulcrum to lift loads.'},
      {'heading': 'Pulleys', 'body': 'A pulley changes the direction of force.'},
    ],
    'quiz': {
      'id': 7,
      'slug': 'simple-machines-quiz',
      'title': 'Simple Machines Quiz',
      'question_count': 4,
    },
    'flashcards': [
      {'front': 'What is a lever?', 'back': 'A simple machine.'},
    ],
  })!;
}

void main() {
  group('StudyPackData.parse', () {
    test('parses a Map payload with lesson, quiz, and flashcards', () {
      final pack = _samplePack();
      expect(pack.lesson.length, 2);
      expect(pack.lesson.first.heading, 'Levers');
      expect(pack.quizSlug, 'simple-machines-quiz');
      expect(pack.quizQuestionCount, 4);
      expect(pack.hasQuiz, isTrue);
      expect(pack.flashcards.single.front, 'What is a lever?');
    });

    test('parses a JSON-encoded string (graphene JSONString)', () {
      const raw =
          '{"lesson":[{"heading":"H","body":"B"}],"quiz":{"slug":"q","title":"Q","question_count":2},"flashcards":[]}';
      final pack = StudyPackData.parse(raw);
      expect(pack, isNotNull);
      expect(pack!.lesson.single.body, 'B');
      expect(pack.quizSlug, 'q');
      expect(pack.hasFlashcards, isFalse);
    });

    test('returns null for null, empty, or malformed data', () {
      expect(StudyPackData.parse(null), isNull);
      expect(StudyPackData.parse(''), isNull);
      expect(StudyPackData.parse('not json'), isNull);
      expect(StudyPackData.parse({'lesson': [], 'flashcards': []}), isNull);
    });
  });

  group('StudyPackCard states', () {
    testWidgets('shows the generate CTA when nothing exists yet',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StudyPackCard(
            pack: null,
            isGenerating: false,
            hasFailed: false,
            statusLabel: '',
            onGenerate: () {},
            onOpen: null,
          ),
        ),
      ));

      expect(find.byKey(const Key('study_pack_generate')), findsOneWidget);
      expect(find.text('Make Study Pack'), findsOneWidget);
      expect(find.byKey(const Key('study_pack_generating')), findsNothing);
      expect(find.byKey(const Key('study_pack_open')), findsNothing);
    });

    testWidgets('shows the generating state while a task is active',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StudyPackCard(
            pack: null,
            isGenerating: true,
            hasFailed: false,
            statusLabel: 'Building your study pack…',
            onGenerate: () {},
            onOpen: null,
          ),
        ),
      ));

      expect(find.byKey(const Key('study_pack_generating')), findsOneWidget);
      expect(find.text('Generating…'), findsOneWidget);
      expect(find.byKey(const Key('study_pack_generate')), findsNothing);
    });

    testWidgets('shows the open CTA when the pack is ready', (tester) async {
      var opened = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StudyPackCard(
            pack: _samplePack(),
            isGenerating: false,
            hasFailed: false,
            statusLabel: '',
            onGenerate: () {},
            onOpen: () => opened = true,
          ),
        ),
      ));

      final openBtn = find.byKey(const Key('study_pack_open'));
      expect(openBtn, findsOneWidget);
      expect(find.text('Open Study Pack'), findsOneWidget);
      await tester.tap(openBtn);
      expect(opened, isTrue);
    });

    testWidgets('shows a retry CTA after a failure', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StudyPackCard(
            pack: null,
            isGenerating: false,
            hasFailed: true,
            statusLabel: '',
            onGenerate: () {},
            onOpen: null,
          ),
        ),
      ));

      expect(find.text('Try again'), findsOneWidget);
    });
  });

  testWidgets('StudyPackSheet renders lesson, quiz, and flashcards',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: StudyPackSheet(pack: _samplePack())),
    ));
    // DraggableScrollableSheet needs an initial pump to lay out, then a short
    // pump for the scroll physics to settle — pumpAndSettle may loop forever.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Your Study Pack'), findsOneWidget);
    expect(find.text('Levers'), findsOneWidget);
    expect(find.text('Simple Machines Quiz'), findsOneWidget);
    expect(find.textContaining('4 questions'), findsOneWidget);
    expect(find.text('What is a lever?', skipOffstage: false), findsOneWidget);
  });
}
