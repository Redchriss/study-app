import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final quizDisplaySchema = S.object(
  properties: {
    'component': S.string(enumValues: ['QuizDisplay']),
    'question': S.string(description: 'The quiz question text'),
    'options': S.list(
      description: 'The multiple choice options',
      items: S.string(),
    ),
    'answerAction': A2uiSchemas.action(
      description:
          'The action performed when the user selects an answer. Passes the selected index.',
    ),
  },
  required: ['component', 'question', 'options', 'answerAction'],
);

class _QuizDisplayData {
  final String question;
  final List<String> options;
  final String actionName;
  final JsonMap actionContext;

  _QuizDisplayData({
    required this.question,
    required this.options,
    required this.actionName,
    required this.actionContext,
  });

  factory _QuizDisplayData.fromJson(Map<String, Object?> json) {
    try {
      final action = json['answerAction'] as JsonMap;
      final event = action['event'] as JsonMap;

      return _QuizDisplayData(
        question: json['question'] as String,
        options: (json['options'] as List<Object?>).cast<String>(),
        actionName: event['name'] as String,
        actionContext: event['context'] as JsonMap,
      );
    } catch (e) {
      throw Exception('Invalid JSON for _QuizDisplayData: $e');
    }
  }
}

class _QuizDisplay extends StatefulWidget {
  final _QuizDisplayData data;
  final void Function(int selectedIndex) onSelectAnswer;

  const _QuizDisplay({required this.data, required this.onSelectAnswer});

  @override
  State<_QuizDisplay> createState() => _QuizDisplayState();
}

class _QuizDisplayState extends State<_QuizDisplay> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.quiz, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Quiz Time',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    )),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.data.question,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            ...List.generate(widget.data.options.length, (index) {
              final isSelected = _selectedIndex == index;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: _selectedIndex == null
                      ? () {
                          setState(() {
                            _selectedIndex = index;
                          });
                          widget.onSelectAnswer(index);
                        }
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : null,
                    ),
                    child: Text(
                      widget.data.options[index],
                      style: TextStyle(
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

final quizDisplayItem = CatalogItem(
  name: 'QuizDisplay',
  dataSchema: quizDisplaySchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _QuizDisplayData.fromJson(json);

    return _QuizDisplay(
      data: data,
      onSelectAnswer: (index) async {
        final resolvedContext = await resolveContext(
          itemContext.dataContext,
          data.actionContext,
        );

        // Add the selected index to the context so the AI knows what was picked
        final finalContext = Map<String, Object?>.from(resolvedContext);
        finalContext['selectedIndex'] = index;
        finalContext['selectedAnswer'] = data.options[index];

        itemContext.dispatchEvent(
          UserActionEvent(
            name: data.actionName,
            sourceComponentId: itemContext.id,
            context: finalContext,
          ),
        );
      },
    );
  },
);
