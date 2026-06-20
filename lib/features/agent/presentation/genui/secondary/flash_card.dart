import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'flash_card_data.dart';
import 'flash_card_widget.dart';

final flashCardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['FlashCard']),
    'front_text': S.string(description: 'Term, question, or concept to recall'),
    'back_text': S.string(description: 'Definition, answer, or explanation'),
    'subject_tag':
        S.string(description: 'Subject abbreviation e.g. BIO, CHE, PHY'),
    'example':
        S.string(description: 'Optional worked example or usage sentence'),
    'recallAction': A2uiSchemas.action(
      description: 'Dispatched after student rates recall',
    ),
  },
  required: ['component', 'front_text', 'back_text', 'recallAction'],
);

final flashCardItem = CatalogItem(
  name: 'FlashCard',
  dataSchema: flashCardSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = FlashCardData.fromJson(json);
    return FlashCardWidget(
      data: data,
      onRecall: (rating) async {
        final resolvedContext = await resolveContext(
          itemContext.dataContext,
          data.actionContext,
        );
        final finalContext = Map<String, Object?>.from(resolvedContext);
        finalContext['rating'] = rating;
        finalContext['frontText'] = data.frontText;
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
