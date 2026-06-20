import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'code_snippet_card_data.dart';
import 'code_snippet_card_widget.dart';

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

final codeSnippetCardItem = CatalogItem(
  name: 'CodeSnippetCard',
  dataSchema: codeSnippetCardSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = CodeSnippetCardData.fromJson(json);
    return CodeSnippetCardWidget(
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
