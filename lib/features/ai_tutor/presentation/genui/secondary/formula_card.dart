import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'formula_card_data.dart';
import 'formula_card_widget.dart';

final formulaCardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['FormulaCard']),
    'formula_name': S.string(description: 'Name of the formula or law'),
    'formula': S.string(
      description: 'The formula itself in plain text e.g. "F = ma"',
    ),
    'variables': S.list(
      items: S.object(properties: {
        'symbol': S.string(description: 'Variable symbol'),
        'meaning': S.string(description: 'What the variable represents'),
        'unit': S.string(description: 'SI unit e.g. kg, m/s², N'),
      }),
    ),
    'worked_example': S.string(
      description: 'One concrete worked example using realistic values',
    ),
    'msce_tip': S.string(
      description: 'Common MSCE exam mistake to avoid when using this formula',
    ),
  },
  required: [
    'component',
    'formula_name',
    'formula',
    'variables',
    'worked_example',
  ],
);

final formulaCardItem = CatalogItem(
  name: 'FormulaCard',
  dataSchema: formulaCardSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = FormulaCardData.fromJson(json);
    return FormulaCardWidget(data: data);
  },
);
