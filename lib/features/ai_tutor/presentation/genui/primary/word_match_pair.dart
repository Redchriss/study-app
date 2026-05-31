import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'word_match_pair_data.dart';
import 'word_match_pair_widget.dart';

final wordMatchPairSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['WordMatchPair']),
    'pairs': S.list(
      description: 'Exactly 3 or 4 pairs',
      items: S.object(properties: {
        'left': S.string(description: 'Word or phrase on the left side'),
        'right':
            S.string(description: 'Matching definition, translation, or value'),
      }),
    ),
    'matchCompleteAction': A2uiSchemas.action(
      description: 'Dispatched when all pairs are correctly matched',
    ),
  },
  required: ['component', 'pairs', 'matchCompleteAction'],
);

final wordMatchPairItem = CatalogItem(
  name: 'WordMatchPair',
  dataSchema: wordMatchPairSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = WordMatchPairData.fromJson(json);
    return WordMatchPairWidget(
      data: data,
      onComplete: () async {
        final resolvedContext = await resolveContext(
          itemContext.dataContext,
          data.actionContext,
        );
        itemContext.dispatchEvent(
          UserActionEvent(
            name: data.actionName,
            sourceComponentId: itemContext.id,
            context: resolvedContext,
          ),
        );
      },
    );
  },
);
