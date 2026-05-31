import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'math_visual_board_data.dart';
import 'math_visual_board_widget.dart';

final mathVisualBoardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['MathVisualBoard']),
    'emoji': S.string(description: 'Emoji object to use for visual counting'),
    'operand_a': S.integer(description: 'First number (shown as emoji array)'),
    'operator': S.string(
      enumValues: ['+', '-'],
      description: 'Operation to perform',
    ),
    'operand_b': S.integer(description: 'Second number'),
    'answer_choices': S.list(
      description: 'Three integer choices, one being the correct answer',
      items: S.integer(),
    ),
    'answerAction': A2uiSchemas.action(
      description: 'Dispatched when student selects answer',
    ),
  },
  required: [
    'component',
    'emoji',
    'operand_a',
    'operator',
    'operand_b',
    'answer_choices',
    'answerAction',
  ],
);

final mathVisualBoardItem = CatalogItem(
  name: 'MathVisualBoard',
  dataSchema: mathVisualBoardSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = MathVisualBoardData.fromJson(json);
    return MathVisualBoardWidget(
      data: data,
      onAnswer: (isCorrect, selectedAnswer) async {
        final resolvedContext = await resolveContext(
          itemContext.dataContext,
          data.actionContext,
        );
        final finalContext = Map<String, Object?>.from(resolvedContext);
        finalContext['isCorrect'] = isCorrect;
        finalContext['selectedAnswer'] = selectedAnswer;
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
