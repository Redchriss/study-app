import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'argument_builder_data.dart';
import 'argument_builder_widget.dart';

final argumentBuilderSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['ArgumentBuilder']),
    'topic': S.string(description: 'The debate or essay topic'),
    'position': S.string(description: 'The stance the student is arguing for'),
    'claim_prompt': S.string(
      description: 'Guiding prompt for the claim section',
    ),
    'evidence_prompt': S.string(
      description: 'Guiding prompt for evidence',
    ),
    'counter_prompt': S.string(
      description: 'Guiding prompt for counter-argument',
    ),
    'rebuttal_prompt': S.string(
      description: 'Guiding prompt for rebuttal',
    ),
    'reviewAction': A2uiSchemas.action(
      description: 'Dispatched when student requests review of a section',
    ),
  },
  required: [
    'component',
    'topic',
    'position',
    'claim_prompt',
    'evidence_prompt',
    'counter_prompt',
    'rebuttal_prompt',
    'reviewAction',
  ],
);

final argumentBuilderItem = CatalogItem(
  name: 'ArgumentBuilder',
  dataSchema: argumentBuilderSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = ArgumentBuilderData.fromJson(json);
    return ArgumentBuilderWidget(
      data: data,
      onReview: (section, content) async {
        final resolvedContext = await resolveContext(
          itemContext.dataContext,
          data.actionContext,
        );
        final finalContext = Map<String, Object?>.from(resolvedContext);
        finalContext['section'] = section;
        finalContext['content'] = content;
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
