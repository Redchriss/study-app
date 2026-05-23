import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

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

class _NodeData {
  final String id;
  final String label;
  final bool isCentral;

  _NodeData({required this.id, required this.label, required this.isCentral});

  factory _NodeData.fromJson(Map<String, Object?> json) {
    return _NodeData(
      id: (json['id'] as String?) ?? '',
      label: (json['label'] as String?) ?? '',
      isCentral: (json['is_central'] as num?)?.toInt() == 1,
    );
  }
}

class _EdgeData {
  final String fromId;
  final String toId;
  final String relationship;

  _EdgeData(
      {required this.fromId, required this.toId, required this.relationship});

  factory _EdgeData.fromJson(Map<String, Object?> json) {
    return _EdgeData(
      fromId: (json['from_id'] as String?) ?? '',
      toId: (json['to_id'] as String?) ?? '',
      relationship: (json['relationship'] as String?) ?? '',
    );
  }
}

class _ConceptMapData {
  final String title;
  final List<_NodeData> nodes;
  final List<_EdgeData> edges;
  final String actionName;
  final JsonMap actionContext;

  _ConceptMapData({
    required this.title,
    required this.nodes,
    required this.edges,
    required this.actionName,
    required this.actionContext,
  });

  factory _ConceptMapData.fromJson(Map<String, Object?> json) {
    final action = json['nodeExpandAction'] as JsonMap?;
    final event = action?['event'] as JsonMap?;
    final nodesRaw = json['nodes'] as List<dynamic>?;
    final edgesRaw = json['edges'] as List<dynamic>?;
    return _ConceptMapData(
      title: (json['title'] as String?) ?? '',
      nodes: nodesRaw
              ?.map((e) => _NodeData.fromJson(e as Map<String, Object?>))
              .toList() ??
          [],
      edges: edgesRaw
              ?.map((e) => _EdgeData.fromJson(e as Map<String, Object?>))
              .toList() ??
          [],
      actionName: (event?['name'] as String?) ?? 'node_expand',
      actionContext: (event?['context'] as JsonMap?) ?? {},
    );
  }
}

class _ConceptMapWidget extends StatefulWidget {
  final _ConceptMapData data;
  final void Function(String nodeId, String nodeLabel) onNodeTap;

  const _ConceptMapWidget({required this.data, required this.onNodeTap});

  @override
  State<_ConceptMapWidget> createState() => _ConceptMapWidgetState();
}

class _ConceptMapWidgetState extends State<_ConceptMapWidget>
    with SingleTickerProviderStateMixin {
  Offset _pan = Offset.zero;
  late final AnimationController _ctrl;
  late final Animation<double> _entrance;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entrance = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return FadeTransition(
      opacity: _entrance,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.data.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GestureDetector(
                  onPanUpdate: (d) {
                    setState(() {
                      _pan += d.delta;
                    });
                  },
                  child: CustomPaint(
                    size: const Size(double.infinity, 300),
                    painter: _MapPainter(
                      nodes: widget.data.nodes,
                      edges: widget.data.edges,
                      pan: _pan,
                      cs: cs,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap a concept to learn more',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final List<_NodeData> nodes;
  final List<_EdgeData> edges;
  final Offset pan;
  final ColorScheme cs;

  _MapPainter({
    required this.nodes,
    required this.edges,
    required this.pan,
    required this.cs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2 + pan.dx, size.height / 2 + pan.dy);
    final positions = <String, Offset>{};

    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final angle = (2 * math.pi * i) / nodes.length - math.pi / 2;
      final radius = node.isCentral ? 0.0 : size.width * 0.32;
      positions[node.id] = Offset(
        centre.dx + radius * math.cos(angle),
        centre.dy + radius * math.sin(angle),
      );
    }

    for (final edge in edges) {
      final from = positions[edge.fromId];
      final to = positions[edge.toId];
      if (from == null || to == null) continue;
      final linePaint = Paint()
        ..color = cs.outlineVariant
        ..strokeWidth = 1.5;
      canvas.drawLine(from, to, linePaint);

      final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
      final bg = Paint()..color = cs.surface;
      canvas.drawCircle(mid, 24, bg);
      final label = TextPainter(
        text: TextSpan(
          text: edge.relationship,
          style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 48);
      label.paint(canvas, mid - Offset(label.width / 2, label.height / 2));
    }

    for (final node in nodes) {
      final pos = positions[node.id];
      if (pos == null) continue;
      final w = node.isCentral ? 80.0 : 60.0;
      final h = node.isCentral ? 40.0 : 32.0;
      final rect = Rect.fromCenter(center: pos, width: w, height: h);
      final bgPaint = Paint()
        ..color = node.isCentral ? cs.primaryContainer : cs.secondaryContainer;
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(8)), bgPaint);

      final label = TextPainter(
        text: TextSpan(
          text: node.label,
          style: TextStyle(
            fontSize: node.isCentral ? 13 : 11,
            fontWeight: FontWeight.w600,
            color: node.isCentral
                ? cs.onPrimaryContainer
                : cs.onSecondaryContainer,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: w - 8);
      label.paint(
          canvas, Offset(pos.dx - label.width / 2, pos.dy - label.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => old.pan != pan;
}

final conceptMapItem = CatalogItem(
  name: 'ConceptMap',
  dataSchema: conceptMapSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _ConceptMapData.fromJson(json);
    return _ConceptMapWidget(
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
