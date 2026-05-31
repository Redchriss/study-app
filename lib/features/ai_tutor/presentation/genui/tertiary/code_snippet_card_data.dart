import 'package:genui/genui.dart';

class AnnotationData {
  final int lineNumber;
  final String note;

  AnnotationData({required this.lineNumber, required this.note});

  factory AnnotationData.fromJson(Map<String, Object?> json) {
    return AnnotationData(
      lineNumber: (json['line_number'] as num?)?.toInt() ?? 0,
      note: (json['note'] as String?) ?? '',
    );
  }
}

class CodeSnippetCardData {
  final String language;
  final String code;
  final List<AnnotationData> annotations;
  final String expectedOutput;
  final String? conceptTag;
  final String actionName;
  final JsonMap actionContext;

  CodeSnippetCardData({
    required this.language,
    required this.code,
    required this.annotations,
    required this.expectedOutput,
    this.conceptTag,
    required this.actionName,
    required this.actionContext,
  });

  List<String> get codeLines => code.split('\n');

  factory CodeSnippetCardData.fromJson(Map<String, Object?> json) {
    final action = json['lineExplainAction'] as JsonMap?;
    final event = action?['event'] as JsonMap?;
    final annotationsRaw = json['annotations'] as List<dynamic>?;
    return CodeSnippetCardData(
      language: (json['language'] as String?) ?? 'python',
      code: (json['code'] as String?) ?? '',
      annotations: annotationsRaw
              ?.map((e) => AnnotationData.fromJson(e as Map<String, Object?>))
              .toList() ??
          [],
      expectedOutput: (json['expected_output'] as String?) ?? '',
      conceptTag: json['concept_tag'] as String?,
      actionName: (event?['name'] as String?) ?? 'line_explain',
      actionContext: (event?['context'] as JsonMap?) ?? {},
    );
  }
}
