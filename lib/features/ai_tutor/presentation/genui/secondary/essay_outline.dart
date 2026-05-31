import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'essay_outline_data.dart';
import 'essay_outline_widget.dart';

final essayOutlineSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['EssayOutline']),
    'essay_question':
        S.string(description: 'The essay question this outline addresses'),
    'thesis': S.string(description: 'The central argument or thesis statement'),
    'points': S.list(
      description: 'Between 2 and 4 main points',
      items: S.object(properties: {
        'heading': S.string(description: 'Main point heading'),
        'evidence': S.string(description: 'Supporting evidence or example'),
        'link_back':
            S.string(description: 'How this point links back to the thesis'),
      }),
    ),
    'conclusion_note':
        S.string(description: 'What the conclusion should address'),
  },
  required: ['component', 'essay_question', 'thesis', 'points'],
);

final essayOutlineItem = CatalogItem(
  name: 'EssayOutline',
  dataSchema: essayOutlineSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = EssayOutlineData.fromJson(json);
    return EssayOutlineWidget(data: data);
  },
);
