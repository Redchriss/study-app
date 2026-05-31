import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'simple_quiz_data.dart';
import 'simple_quiz_widget.dart';

final simpleQuizSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['SimpleQuiz']),
    'question': S.string(
      description: 'Question in simple English or Chichewa, max 20 words',
    ),
    'options': S.list(
      description: '3 or 4 answer options',
      items: S.object(properties: {
        'emoji':
            S.string(description: 'Emoji that anchors this option visually'),
        'label': S.string(description: 'Option text, max 5 words'),
      }),
    ),
    'correct_index':
        S.integer(description: 'Zero-based index of the correct option'),
    'answerAction': A2uiSchemas.action(
      description:
          'Dispatched after answer is selected, includes isCorrect and selectedIndex',
    ),
  },
  required: [
    'component',
    'question',
    'options',
    'correct_index',
    'answerAction',
  ],
);

final simpleQuizItem = CatalogItem(
  name: 'SimpleQuiz',
  dataSchema: simpleQuizSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = SimpleQuizData.fromJson(json);
    return SimpleQuizWidget(
      data: data,
      onAnswer: (isCorrect, selectedIndex) async {
        final resolvedContext = await resolveContext(
          itemContext.dataContext,
          data.actionContext,
        );
        final finalContext = Map<String, Object?>.from(resolvedContext);
        finalContext['isCorrect'] = isCorrect;
        finalContext['selectedIndex'] = selectedIndex;
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
