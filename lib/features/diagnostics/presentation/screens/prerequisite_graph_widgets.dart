import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

// ── Data models ──────────────────────────────────────────────────────

class GraphTopic {
  final String name;
  final String standardOrForm;
  final List<GraphConcept> concepts;
  final List<GraphEdge> edges;

  GraphTopic({
    required this.name,
    required this.standardOrForm,
    required this.concepts,
    required this.edges,
  });
}

class GraphConcept {
  final String slug;
  final String name;
  final String conceptType;
  final double difficulty;
  final double mastery; // -1 = unknown, 0-1 = P(known)

  GraphConcept({
    required this.slug,
    required this.name,
    required this.conceptType,
    required this.difficulty,
    required this.mastery,
  });

  Color get color {
    if (mastery < 0) return DesignTokens.textTertiary;
    if (mastery >= 0.8) return DesignTokens.success;
    if (mastery >= 0.4) return DesignTokens.warning;
    return DesignTokens.error;
  }

  String get typeIcon {
    switch (conceptType) {
      case 'knowledge':
        return '📖';
      case 'procedure':
        return '⚙️';
      case 'conceptual':
        return '💡';
      case 'meta':
        return '🧠';
      default:
        return '•';
    }
  }
}

class GraphEdge {
  final String fromSlug;
  final String toSlug;
  final double strength;

  GraphEdge({
    required this.fromSlug,
    required this.toSlug,
    required this.strength,
  });
}

// ── Topic card widget ────────────────────────────────────────────────

class TopicGraphCard extends StatelessWidget {
  final GraphTopic topic;
  final bool dark;
  final String? selectedConcept;
  final ValueChanged<String> onSelectConcept;

  const TopicGraphCard({
    super.key,
    required this.topic,
    required this.dark,
    required this.selectedConcept,
    required this.onSelectConcept,
  });

  @override
  Widget build(BuildContext context) {
    final mastered = topic.concepts.where((c) => c.mastery >= 0.8).length;
    final total = topic.concepts.length;
    final pct = total > 0 ? (mastered / total * 100).round() : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(topic.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                      if (topic.standardOrForm.isNotEmpty)
                        Text(topic.standardOrForm,
                            style: const TextStyle(
                                fontSize: 11,
                                color: DesignTokens.textSecondary)),
                    ],
                  ),
                ),
                Text('$mastered/$total',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: DesignTokens.textSecondary)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 4,
                backgroundColor:
                    dark ? Colors.white12 : Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(
                  pct >= 70
                      ? DesignTokens.success
                      : pct >= 40
                          ? DesignTokens.warning
                          : DesignTokens.error,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (topic.concepts.isNotEmpty)
              SizedBox(
                height: _calculateHeight(topic.concepts.length),
                child: CustomPaint(
                  painter: GraphEdgePainter(
                    concepts: topic.concepts,
                    edges: topic.edges,
                    selectedConcept: selectedConcept,
                    dark: dark,
                  ),
                  child: ConceptFlowLayout(
                    concepts: topic.concepts,
                    edges: topic.edges,
                    selectedConcept: selectedConcept,
                    onSelectConcept: onSelectConcept,
                  ),
                ),
              ),
            if (topic.concepts.isEmpty)
              const Text('No concepts mapped yet',
                  style: TextStyle(
                      color: DesignTokens.textTertiary, fontSize: 13)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  double _calculateHeight(int conceptCount) {
    final rows = (conceptCount / 3).ceil();
    return (rows * 72.0).clamp(72.0, 500.0);
  }
}

// ── Concept flow layout ──────────────────────────────────────────────

class ConceptFlowLayout extends StatelessWidget {
  final List<GraphConcept> concepts;
  final List<GraphEdge> edges;
  final String? selectedConcept;
  final ValueChanged<String> onSelectConcept;

  const ConceptFlowLayout({
    super.key,
    required this.concepts,
    required this.edges,
    required this.selectedConcept,
    required this.onSelectConcept,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: concepts.map((c) {
          final isSelected = selectedConcept == c.slug;
          final hasPrereqs = edges.any((e) => e.toSlug == c.slug);
          final isPrereqOf = edges.any((e) => e.fromSlug == c.slug);

          return GestureDetector(
            onTap: () => onSelectConcept(c.slug),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              constraints: const BoxConstraints(maxWidth: 160),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: c.color.withValues(alpha: isSelected ? 0.2 : 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? c.color
                      : c.color.withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(c.typeIcon, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(c.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: c.color)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasPrereqs)
                        const Icon(Icons.arrow_back_rounded,
                            size: 10, color: DesignTokens.textTertiary),
                      if (hasPrereqs) const SizedBox(width: 2),
                      if (c.mastery >= 0)
                        Text('${(c.mastery * 100).round()}%',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: c.color))
                      else
                        const Text('—',
                            style: TextStyle(
                                fontSize: 10,
                                color: DesignTokens.textTertiary)),
                      if (isPrereqOf) const SizedBox(width: 2),
                      if (isPrereqOf)
                        const Icon(Icons.arrow_forward_rounded,
                            size: 10, color: DesignTokens.textTertiary),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Edge painter ─────────────────────────────────────────────────────

class GraphEdgePainter extends CustomPainter {
  final List<GraphConcept> concepts;
  final List<GraphEdge> edges;
  final String? selectedConcept;
  final bool dark;

  GraphEdgePainter({
    required this.concepts,
    required this.edges,
    required this.selectedConcept,
    required this.dark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (edges.isEmpty || concepts.isEmpty) return;

    final conceptPositions = <String, Offset>{};
    double x = 8;
    double y = 8;
    const cardWidth = 168.0;
    const cardHeight = 64.0;
    const spacing = 8.0;

    for (final c in concepts) {
      conceptPositions[c.slug] = Offset(
        x + cardWidth / 2,
        y + cardHeight / 2,
      );
      x += cardWidth + spacing;
      if (x > size.width - cardWidth) {
        x = 8;
        y += cardHeight + spacing;
      }
    }

    for (final edge in edges) {
      final from = conceptPositions[edge.fromSlug];
      final to = conceptPositions[edge.toSlug];
      if (from != null && to != null) {
        final edgePaint = Paint()
          ..color = (dark ? Colors.white : Colors.black)
              .withValues(alpha: 0.08 * edge.strength)
          ..strokeWidth = 1.0 + edge.strength
          ..style = PaintingStyle.stroke;

        canvas.drawLine(from, to, edgePaint);

        final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
        final arrowLen = 8.0;
        final arrowAngle = 0.4;
        final arrowPaint = Paint()
          ..color = edgePaint.color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

        canvas.drawLine(
          to,
          Offset(
            to.dx - arrowLen * math.cos(angle - arrowAngle),
            to.dy - arrowLen * math.sin(angle - arrowAngle),
          ),
          arrowPaint,
        );
        canvas.drawLine(
          to,
          Offset(
            to.dx - arrowLen * math.cos(angle + arrowAngle),
            to.dy - arrowLen * math.sin(angle + arrowAngle),
          ),
          arrowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
