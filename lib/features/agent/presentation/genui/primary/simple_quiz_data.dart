import 'package:genui/genui.dart';

class SimpleQuizOption {
  final String emoji;
  final String label;

  SimpleQuizOption({required this.emoji, required this.label});

  factory SimpleQuizOption.fromJson(Map<String, Object?> json) {
    return SimpleQuizOption(
      emoji: (json['emoji'] as String?) ?? '',
      label: (json['label'] as String?) ?? '',
    );
  }
}

class SimpleQuizData {
  final String question;
  final List<SimpleQuizOption> options;
  final int correctIndex;
  final String actionName;
  final JsonMap actionContext;

  SimpleQuizData({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.actionName,
    required this.actionContext,
  });

  factory SimpleQuizData.fromJson(Map<String, Object?> json) {
    final action = json['answerAction'] as JsonMap?;
    final event = action?['event'] as JsonMap?;
    final optionsRaw = json['options'] as List<dynamic>?;
    return SimpleQuizData(
      question: (json['question'] as String?) ?? '',
      options: optionsRaw
              ?.map((e) => SimpleQuizOption.fromJson(e as Map<String, Object?>))
              .toList() ??
          [],
      correctIndex: (json['correct_index'] as num?)?.toInt() ?? 0,
      actionName: (event?['name'] as String?) ?? 'answered',
      actionContext: (event?['context'] as JsonMap?) ?? {},
    );
  }
}
