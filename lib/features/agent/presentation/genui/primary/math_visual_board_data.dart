import 'package:genui/genui.dart';

class MathVisualBoardData {
  final String emoji;
  final int operandA;
  final String operator;
  final int operandB;
  final List<int> answerChoices;
  final String actionName;
  final JsonMap actionContext;

  MathVisualBoardData({
    required this.emoji,
    required this.operandA,
    required this.operator,
    required this.operandB,
    required this.answerChoices,
    required this.actionName,
    required this.actionContext,
  });

  int get correctAnswer =>
      operator == '+' ? operandA + operandB : operandA - operandB;

  factory MathVisualBoardData.fromJson(Map<String, Object?> json) {
    final action = json['answerAction'] as JsonMap?;
    final event = action?['event'] as JsonMap?;
    final choices = json['answer_choices'] as List<dynamic>?;
    return MathVisualBoardData(
      emoji: (json['emoji'] as String?) ?? '🍎',
      operandA: (json['operand_a'] as num?)?.toInt() ?? 0,
      operator: (json['operator'] as String?) ?? '+',
      operandB: (json['operand_b'] as num?)?.toInt() ?? 0,
      answerChoices: choices?.map((e) => (e as num).toInt()).toList() ?? [],
      actionName: (event?['name'] as String?) ?? 'answered',
      actionContext: (event?['context'] as JsonMap?) ?? {},
    );
  }
}
