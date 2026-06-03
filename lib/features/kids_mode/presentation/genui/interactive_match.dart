import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'interactive_match_data.dart';
import 'interactive_match_widget.dart';

final interactiveMatchSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['InteractiveMatch']),
    'question':
        S.string(description: 'The question asking the child what to find'),
    'options': S.list(
      description: 'The emoji options to pick from',
      items: S.object(
        properties: {
          'emoji': S.string(description: 'The emoji symbol'),
          'label': S.string(description: 'The hidden text label (e.g. "Dog")'),
        },
        required: ['emoji', 'label'],
      ),
    ),
    'correctIndex': S.integer(
        description: 'The array index of the correct option (0, 1, or 2)'),
    'completeAction': A2uiSchemas.action(
      description:
          'The action triggered when the child selects the correct answer.',
    ),
  },
  required: [
    'component',
    'question',
    'options',
    'correctIndex',
    'completeAction'
  ],
);

final interactiveMatchItem = CatalogItem(
  name: 'InteractiveMatch',
  dataSchema: interactiveMatchSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = InteractiveMatchData.fromJson(json);

    return InteractiveMatchWidget(
      data: data,
      onCorrect: () async {
        final resolvedContext = await resolveContext(
          itemContext.dataContext,
          data.actionContext,
        );

        final finalContext = Map<String, Object?>.from(resolvedContext);
        finalContext['answeredCorrectly'] = true;

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
