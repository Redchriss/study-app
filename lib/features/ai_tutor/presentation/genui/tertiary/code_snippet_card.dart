import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final codeSnippetCardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['CodeSnippetCard']),
    'language': S.string(
      enumValues: ['python', 'java', 'c', 'dart', 'javascript', 'sql', 'other'],
    ),
    'code': S.string(description: 'The code snippet, max 20 lines'),
    'annotations': S.list(
      description: 'Up to 5 line annotations',
      items: S.object(properties: {
        'line_number':
            S.integer(description: 'Line number to annotate (1-based)'),
        'note': S.string(description: 'Annotation text, max 10 words'),
      }),
    ),
    'expected_output': S.string(
      description: 'What this code outputs or returns when run',
    ),
    'concept_tag': S.string(
      description:
          'Core CS concept demonstrated e.g. "recursion", "sorting", "OOP"',
    ),
    'lineExplainAction': A2uiSchemas.action(
      description: 'Dispatched when student taps a line for explanation',
    ),
  },
  required: [
    'component',
    'language',
    'code',
    'expected_output',
    'lineExplainAction',
  ],
);

class _AnnotationData {
  final int lineNumber;
  final String note;

  _AnnotationData({required this.lineNumber, required this.note});

  factory _AnnotationData.fromJson(Map<String, Object?> json) {
    return _AnnotationData(
      lineNumber: (json['line_number'] as num?)?.toInt() ?? 0,
      note: (json['note'] as String?) ?? '',
    );
  }
}

class _CodeSnippetCardData {
  final String language;
  final String code;
  final List<_AnnotationData> annotations;
  final String expectedOutput;
  final String? conceptTag;
  final String actionName;
  final JsonMap actionContext;

  _CodeSnippetCardData({
    required this.language,
    required this.code,
    required this.annotations,
    required this.expectedOutput,
    this.conceptTag,
    required this.actionName,
    required this.actionContext,
  });

  List<String> get codeLines => code.split('\n');

  factory _CodeSnippetCardData.fromJson(Map<String, Object?> json) {
    final action = json['lineExplainAction'] as JsonMap?;
    final event = action?['event'] as JsonMap?;
    final annotationsRaw = json['annotations'] as List<dynamic>?;
    return _CodeSnippetCardData(
      language: (json['language'] as String?) ?? 'python',
      code: (json['code'] as String?) ?? '',
      annotations: annotationsRaw
              ?.map((e) => _AnnotationData.fromJson(e as Map<String, Object?>))
              .toList() ??
          [],
      expectedOutput: (json['expected_output'] as String?) ?? '',
      conceptTag: json['concept_tag'] as String?,
      actionName: (event?['name'] as String?) ?? 'line_explain',
      actionContext: (event?['context'] as JsonMap?) ?? {},
    );
  }
}

class _CodeSnippetCardWidget extends StatefulWidget {
  final _CodeSnippetCardData data;
  final void Function(int lineNumber, String lineContent) onLineTap;
  final VoidCallback onOutputReveal;

  const _CodeSnippetCardWidget({
    required this.data,
    required this.onLineTap,
    required this.onOutputReveal,
  });

  @override
  State<_CodeSnippetCardWidget> createState() => _CodeSnippetCardWidgetState();
}

class _CodeSnippetCardWidgetState extends State<_CodeSnippetCardWidget>
    with SingleTickerProviderStateMixin {
  bool _showOutput = false;
  late final AnimationController _ctrl;
  late final Animation<double> _entrance;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entrance = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggleOutput() {
    setState(() => _showOutput = !_showOutput);
    if (!_showOutput) widget.onOutputReveal();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = widget.data.codeLines;

    return FadeTransition(
      opacity: _entrance,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade800,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.data.language,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (widget.data.conceptTag != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    widget.data.conceptTag!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(lines.length, (i) {
                  final lineNo = i + 1;
                  final annotation = widget.data.annotations
                      .where((a) => a.lineNumber == lineNo)
                      .firstOrNull;
                  return GestureDetector(
                    onTap: () => widget.onLineTap(lineNo, lines[i]),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text(
                              '$lineNo',
                              style: const TextStyle(
                                color: Color(0xFF858585),
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                  color: Color(0xFFD4D4D4),
                                  height: 1.5,
                                ),
                                children: [
                                  TextSpan(text: lines[i]),
                                  if (annotation != null)
                                    TextSpan(
                                      text: '  // ${annotation.note}',
                                      style: TextStyle(
                                        color: Colors.green.shade300,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _toggleOutput,
              icon: Icon(
                _showOutput ? Icons.visibility_off : Icons.play_arrow,
                size: 16,
              ),
              label: Text(
                _showOutput ? 'Hide output' : 'Predict output ▸',
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: _showOutput
                  ? Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.data.expectedOutput,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFFCE9178),
                          fontSize: 13,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

final codeSnippetCardItem = CatalogItem(
  name: 'CodeSnippetCard',
  dataSchema: codeSnippetCardSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _CodeSnippetCardData.fromJson(json);
    return _CodeSnippetCardWidget(
      data: data,
      onLineTap: (lineNumber, lineContent) async {
        final resolvedContext = await resolveContext(
          itemContext.dataContext,
          data.actionContext,
        );
        final finalContext = Map<String, Object?>.from(resolvedContext);
        finalContext['lineNumber'] = lineNumber;
        finalContext['lineContent'] = lineContent;
        itemContext.dispatchEvent(
          UserActionEvent(
            name: data.actionName,
            sourceComponentId: itemContext.id,
            context: finalContext,
          ),
        );
      },
      onOutputReveal: () {},
    );
  },
);
