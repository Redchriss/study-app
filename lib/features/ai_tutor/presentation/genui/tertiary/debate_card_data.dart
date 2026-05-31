import 'package:genui/genui.dart';

class DebateCardData {
  final String question;
  final String sideALabel;
  final String sideAArgument;
  final String sideBLabel;
  final String sideBArgument;
  final String? context;
  final String actionName;
  final JsonMap actionContext;

  DebateCardData({
    required this.question,
    required this.sideALabel,
    required this.sideAArgument,
    required this.sideBLabel,
    required this.sideBArgument,
    this.context,
    required this.actionName,
    required this.actionContext,
  });

  factory DebateCardData.fromJson(Map<String, Object?> json) {
    final action = json['debateAction'] as JsonMap?;
    final event = action?['event'] as JsonMap?;
    return DebateCardData(
      question: (json['question'] as String?) ?? '',
      sideALabel: (json['side_a_label'] as String?) ?? '',
      sideAArgument: (json['side_a_argument'] as String?) ?? '',
      sideBLabel: (json['side_b_label'] as String?) ?? '',
      sideBArgument: (json['side_b_argument'] as String?) ?? '',
      context: json['context'] as String?,
      actionName: (event?['name'] as String?) ?? 'debate',
      actionContext: (event?['context'] as JsonMap?) ?? {},
    );
  }
}
