import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final researchSummarySchema = S.object(
  properties: {
    'component': S.string(enumValues: ['ResearchSummary']),
    'paper_title': S.string(
        description: 'Title or topic of the research being summarised'),
    'background':
        S.string(description: 'Why this research matters, 1-2 sentences'),
    'methodology':
        S.string(description: 'How the research was done, 1-2 sentences'),
    'findings':
        S.string(description: 'Key results, 2-3 bullet points as a string'),
    'limitations':
        S.string(description: 'What the research cannot tell us, 1 sentence'),
    'implications': S.string(
        description:
            'What this means for the field or for Malawi specifically, 1-2 sentences'),
  },
  required: [
    'component',
    'paper_title',
    'background',
    'methodology',
    'findings',
  ],
);

class _ResearchSummaryData {
  final String paperTitle;
  final String background;
  final String methodology;
  final String findings;
  final String? limitations;
  final String? implications;

  _ResearchSummaryData({
    required this.paperTitle,
    required this.background,
    required this.methodology,
    required this.findings,
    this.limitations,
    this.implications,
  });

  factory _ResearchSummaryData.fromJson(Map<String, Object?> json) {
    return _ResearchSummaryData(
      paperTitle: (json['paper_title'] as String?) ?? '',
      background: (json['background'] as String?) ?? '',
      methodology: (json['methodology'] as String?) ?? '',
      findings: (json['findings'] as String?) ?? '',
      limitations: json['limitations'] as String?,
      implications: json['implications'] as String?,
    );
  }
}

class _ResearchSummaryWidget extends StatefulWidget {
  final _ResearchSummaryData data;

  const _ResearchSummaryWidget({required this.data});

  @override
  State<_ResearchSummaryWidget> createState() => _ResearchSummaryWidgetState();
}

class _ResearchSummaryWidgetState extends State<_ResearchSummaryWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _entrance;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entrance = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
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

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _entrance,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.school, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.data.paperTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection('Background', widget.data.background,
                  Icons.info_outline, cs, theme),
              const SizedBox(height: 10),
              _buildSection('Methodology', widget.data.methodology,
                  Icons.biotech, cs, theme),
              const SizedBox(height: 10),
              _buildSection(
                  'Findings', widget.data.findings, Icons.insights, cs, theme),
              if (widget.data.limitations != null) ...[
                const SizedBox(height: 10),
                _buildSection('Limitations', widget.data.limitations!,
                    Icons.warning_amber, cs, theme),
              ],
              if (widget.data.implications != null) ...[
                const SizedBox(height: 10),
                _buildSection('Implications', widget.data.implications!,
                    Icons.trending_up, cs, theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String label, String content, IconData icon,
      ColorScheme cs, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

final researchSummaryItem = CatalogItem(
  name: 'ResearchSummary',
  dataSchema: researchSummarySchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _ResearchSummaryData.fromJson(json);
    return _ResearchSummaryWidget(data: data);
  },
);
