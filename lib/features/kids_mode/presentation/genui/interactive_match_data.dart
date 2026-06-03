import 'package:genui/genui.dart';

class InteractiveMatchOption {
  final String emoji;
  final String label;

  InteractiveMatchOption({required this.emoji, required this.label});

  factory InteractiveMatchOption.fromJson(Map<String, Object?> json) {
    return InteractiveMatchOption(
      emoji: json['emoji'] as String,
      label: json['label'] as String,
    );
  }
}

class InteractiveMatchData {
  final String question;
  final List<InteractiveMatchOption> options;
  final int correctIndex;
  final String actionName;
  final JsonMap actionContext;

  InteractiveMatchData({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.actionName,
    required this.actionContext,
  });

  factory InteractiveMatchData.fromJson(Map<String, Object?> json) {
    try {
      final action = json['completeAction'] as JsonMap;
      final event = action['event'] as JsonMap;

      return InteractiveMatchData(
        question: json['question'] as String,
        options: (json['options'] as List<Object?>)
            .map((e) =>
                InteractiveMatchOption.fromJson(e as Map<String, Object?>))
            .toList(),
        correctIndex: json['correctIndex'] as int,
        actionName: event['name'] as String,
        actionContext: event['context'] as JsonMap,
      );
    } catch (e) {
      throw Exception('Invalid JSON for InteractiveMatchData: $e');
    }
  }
}
