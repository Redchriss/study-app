import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

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

class _PointData {
  final String heading;
  final String evidence;
  final String linkBack;

  _PointData({
    required this.heading,
    required this.evidence,
    required this.linkBack,
  });

  factory _PointData.fromJson(Map<String, Object?> json) {
    return _PointData(
      heading: (json['heading'] as String?) ?? '',
      evidence: (json['evidence'] as String?) ?? '',
      linkBack: (json['link_back'] as String?) ?? '',
    );
  }
}

class _EssayOutlineData {
  final String essayQuestion;
  final String thesis;
  final List<_PointData> points;
  final String? conclusionNote;

  _EssayOutlineData({
    required this.essayQuestion,
    required this.thesis,
    required this.points,
    this.conclusionNote,
  });

  factory _EssayOutlineData.fromJson(Map<String, Object?> json) {
    final pointsRaw = json['points'] as List<dynamic>?;
    return _EssayOutlineData(
      essayQuestion: (json['essay_question'] as String?) ?? '',
      thesis: (json['thesis'] as String?) ?? '',
      points: pointsRaw
              ?.map((e) => _PointData.fromJson(e as Map<String, Object?>))
              .toList() ??
          [],
      conclusionNote: json['conclusion_note'] as String?,
    );
  }
}

class _EssayOutlineWidget extends StatefulWidget {
  final _EssayOutlineData data;

  const _EssayOutlineWidget({required this.data});

  @override
  State<_EssayOutlineWidget> createState() => _EssayOutlineWidgetState();
}

class _EssayOutlineWidgetState extends State<_EssayOutlineWidget>
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
            _buildQuestionHeader(theme, cs),
            const SizedBox(height: 16),
            _buildThesis(theme, cs),
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
              return _buildPointTile(i, theme, cs);
            }),
            if (widget.data.conclusionNote != null) ...[
              const SizedBox(height: 12),
              _buildConclusion(theme, cs),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionHeader(ThemeData theme, ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.article_outlined, size: 20, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.data.essayQuestion,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThesis(ThemeData theme, ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.gps_fixed, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thesis',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.data.thesis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointTile(int index, ThemeData theme, ColorScheme cs) {
    final point = widget.data.points[index];
    final expanded = _expandedPoints.contains(index);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _togglePoint(index),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      point.heading,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: cs.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 4),
                  Text(
                    point.evidence,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.subdirectory_arrow_right,
                          size: 14, color: cs.tertiary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          point.linkBack,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: cs.tertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildConclusion(ThemeData theme, ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.checklist, size: 18, color: cs.onTertiaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conclusion',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onTertiaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.data.conclusionNote!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                    color: cs.onTertiaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final essayOutlineItem = CatalogItem(
  name: 'EssayOutline',
  dataSchema: essayOutlineSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _EssayOutlineData.fromJson(json);
    return _EssayOutlineWidget(data: data);
  },
);
