import 'package:flutter/material.dart';
import 'essay_outline_data.dart';
import 'essay_outline_parts.dart';
import 'essay_outline_point_tile.dart';

class EssayOutlineWidget extends StatefulWidget {
  final EssayOutlineData data;

  const EssayOutlineWidget({super.key, required this.data});

  @override
  State<EssayOutlineWidget> createState() => _EssayOutlineWidgetState();
}

class _EssayOutlineWidgetState extends State<EssayOutlineWidget>
    with SingleTickerProviderStateMixin {
  final Set<int> _expandedPoints = {};
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

  void _togglePoint(int index) {
    setState(() {
      if (_expandedPoints.contains(index)) {
        _expandedPoints.remove(index);
      } else {
        _expandedPoints.add(index);
      }
    });
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
            OutlineQuestionHeader(
              essayQuestion: widget.data.essayQuestion,
              theme: theme,
              cs: cs,
            ),
            const SizedBox(height: 16),
            OutlineThesis(
              thesis: widget.data.thesis,
              theme: theme,
              cs: cs,
            ),
            const SizedBox(height: 16),
            Text(
              'Main points',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(widget.data.points.length, (i) {
              return OutlinePointTile(
                point: widget.data.points[i],
                index: i,
                expanded: _expandedPoints.contains(i),
                onTap: () => _togglePoint(i),
                theme: theme,
                cs: cs,
              );
            }),
            if (widget.data.conclusionNote != null) ...[
              const SizedBox(height: 12),
              OutlineConclusion(
                conclusionNote: widget.data.conclusionNote!,
                theme: theme,
                cs: cs,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
