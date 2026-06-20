import 'package:flutter_test/flutter_test.dart';
import 'package:studyapp/features/materials/presentation/reader/material_reader_helpers.dart';

void main() {
  group('buildReaderAiPrompt', () {
    test('maps the base text actions to distinct prompts', () {
      expect(buildReaderAiPrompt(action: 'summary'),
          contains('Summarize'));
      expect(buildReaderAiPrompt(action: 'memory'),
          contains('mnemonic'));
      expect(buildReaderAiPrompt(action: 'explain'),
          contains('simple language'));
    });

    test('explain_level adapts to the learner profile education level', () {
      final secondary = buildReaderAiPrompt(
        action: 'explain_level',
        educationLevel: 'secondary',
      );
      expect(secondary, contains('a secondary student'));

      // With no profile level it still produces a usable, non-empty prompt.
      final noLevel = buildReaderAiPrompt(action: 'explain_level');
      expect(noLevel, contains('my level'));
      expect(noLevel, isNotEmpty);
    });

    test('translate_chichewa requests a Chichewa rendering', () {
      final prompt = buildReaderAiPrompt(action: 'translate_chichewa');
      expect(prompt.toLowerCase(), contains('chichewa'));
    });

    test('unknown actions fall back to the explain prompt', () {
      expect(buildReaderAiPrompt(action: 'totally_unknown'),
          buildReaderAiPrompt(action: 'explain'));
    });
  });

  group('kReaderAiTextActions', () {
    test('contains the grounded text actions and excludes async ones', () {
      expect(kReaderAiTextActions, containsAll(<String>{
        'explain',
        'summary',
        'memory',
        'explain_level',
        'translate_chichewa',
      }));
      // Quiz + flashcards-from-selection are handled separately, not as text.
      expect(kReaderAiTextActions.contains('quiz_page'), isFalse);
      expect(kReaderAiTextActions.contains('flashcards_selection'), isFalse);
    });
  });
}
