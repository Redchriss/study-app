import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'concept_map_data.dart';
import 'concept_map_widget.dart';

final conceptMapSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['ConceptMap']),
    'title': S.string(description: 'Title of the concept map topic'),
    'nodes': S.list(
      description: 'Between 5 and 10 concept nodes',
      items: S.object(properties: {
        'id': S.string(description: 'Unique identifier for this node'),
        'label': S.string(description: 'Concept name, max 3 words'),
        'is_central': S.integer(
          description: '1 for central node, 0 for peripheral',
        ),
      }),
    ),
    'edges': S.list(
      description: 'Connections between concepts',
      items: S.object(properties: {
        'from_id': S.string(description: 'Source node id'),
        'to_id': S.string(description: 'Target node id'),
        'relationship': S.string(
          description: 'Relationship label, max 4 words',
        ),
      }),
    ),
    'nodeExpandAction': A2uiSchemas.action(
      description: 'Dispatched when student taps a node',
    ),
  },
  required: ['component', 'title', 'nodes', 'edges', 'nodeExpandAction'],
);

final conceptMapItem = CatalogItem(
  name: 'ConceptMap',
  dataSchema: conceptMapSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = ConceptMapData.fromJson(json);
    return ConceptMapWidget(
      data: data,
      onNodeTap: (nodeId, nodeLabel) async {
        final resolvedContext = await resolveContext(
          itemContext.dataContext,
          data.actionContext,
        );
        final finalContext = Map<String, Object?>.from(resolvedContext);
        finalContext['nodeId'] = nodeId;
        finalContext['nodeLabel'] = nodeLabel;
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
