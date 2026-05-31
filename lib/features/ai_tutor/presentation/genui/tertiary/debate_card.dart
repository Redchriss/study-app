import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'debate_card_data.dart';
import 'debate_card_widget.dart';

final debateCardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['DebateCard']),
    'question': S.string(description: 'The contested question or proposition'),
    'side_a_label': S.string(description: 'Label for position A, max 4 words'),
    'side_a_argument': S.string(
      description: 'Core argument for position A, 2-3 sentences',
    ),
    'side_b_label': S.string(description: 'Label for position B, max 4 words'),
    'side_b_argument': S.string(
      description: 'Core argument for position B, 2-3 sentences',
    ),
    'context': S.string(
      description:
          'Optional Malawian or African context that makes this debate locally relevant',
    ),
    'debateAction': A2uiSchemas.action(
      description:
          'Dispatched when student submits their side selection and reasoning',
    ),
  },
  required: [
    'component',
    'question',
    'side_a_label',
    'side_a_argument',
    'side_b_label',
    'side_b_argument',
    'debateAction',
  ],
);

final debateCardItem = CatalogItem(
  name: 'DebateCard',
  dataSchema: debateCardSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = DebateCardData.fromJson(json);
    return DebateCardWidget(
      data: data,
      onSubmit: (selectedSide, reasoning) async {
        final resolvedContext = await resolveContext(
          itemContext.dataContext,
          data.actionContext,
        );
        final finalContext = Map<String, Object?>.from(resolvedContext);
        finalContext['selectedSide'] = selectedSide;
        finalContext['reasoning'] = reasoning;
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
