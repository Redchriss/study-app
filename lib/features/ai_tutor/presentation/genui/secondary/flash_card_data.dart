import 'package:genui/genui.dart';

class FlashCardData {
  final String frontText;
  final String backText;
  final String? subjectTag;
  final String? example;
  final String actionName;
  final JsonMap actionContext;

  FlashCardData({
    required this.frontText,
    required this.backText,
    this.subjectTag,
    this.example,
    required this.actionName,
    required this.actionContext,
  });

  factory FlashCardData.fromJson(Map<String, Object?> json) {
    final action = json['recallAction'] as JsonMap?;
    final event = action?['event'] as JsonMap?;
    return FlashCardData(
      frontText: (json['front_text'] as String?) ?? '',
      backText: (json['back_text'] as String?) ?? '',
      subjectTag: json['subject_tag'] as String?,
      example: json['example'] as String?,
      actionName: (event?['name'] as String?) ?? 'recalled',
      actionContext: (event?['context'] as JsonMap?) ?? {},
    );
  }
}
