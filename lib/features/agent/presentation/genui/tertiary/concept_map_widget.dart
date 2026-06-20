import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'concept_map_data.dart';

class ConceptMapWidget extends StatefulWidget {
  final ConceptMapData data;
  final void Function(String nodeId, String nodeLabel) onNodeTap;

  const ConceptMapWidget(
      {super.key, required this.data, required this.onNodeTap});

  @override
  State<ConceptMapWidget> createState() => _ConceptMapWidgetState();
}

class _ConceptMapWidgetState extends State<ConceptMapWidget>
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
                    painter: MapPainter(
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

class MapPainter extends CustomPainter {
  final List<NodeData> nodes;
  final List<EdgeData> edges;
  final Offset pan;
  final ColorScheme cs;

  MapPainter({
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
  bool shouldRepaint(covariant MapPainter old) => old.pan != pan;
}
