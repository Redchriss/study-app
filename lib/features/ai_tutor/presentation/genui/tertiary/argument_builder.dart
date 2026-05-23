import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

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

const _sections = [
  _SectionConfig('Claim', 'claim', Color(0xFF2196F3)),
  _SectionConfig('Evidence', 'evidence', Color(0xFF4CAF50)),
  _SectionConfig('Counter-argument', 'counter', Color(0xFFFF9800)),
  _SectionConfig('Rebuttal', 'rebuttal', Color(0xFF009688)),
];

class _SectionConfig {
  final String label;
  final String key;
  final Color accent;
  const _SectionConfig(this.label, this.key, this.accent);
}

class _ArgumentBuilderData {
  final String topic;
  final String position;
  final String claimPrompt;
  final String evidencePrompt;
  final String counterPrompt;
  final String rebuttalPrompt;
  final String actionName;
  final JsonMap actionContext;

  _ArgumentBuilderData({
    required this.topic,
    required this.position,
    required this.claimPrompt,
    required this.evidencePrompt,
    required this.counterPrompt,
    required this.rebuttalPrompt,
    required this.actionName,
    required this.actionContext,
  });

  factory _ArgumentBuilderData.fromJson(Map<String, Object?> json) {
    final action = json['reviewAction'] as JsonMap?;
    final event = action?['event'] as JsonMap?;
    return _ArgumentBuilderData(
      topic: (json['topic'] as String?) ?? '',
      position: (json['position'] as String?) ?? '',
      claimPrompt: (json['claim_prompt'] as String?) ?? '',
      evidencePrompt: (json['evidence_prompt'] as String?) ?? '',
      counterPrompt: (json['counter_prompt'] as String?) ?? '',
      rebuttalPrompt: (json['rebuttal_prompt'] as String?) ?? '',
      actionName: (event?['name'] as String?) ?? 'review',
      actionContext: (event?['context'] as JsonMap?) ?? {},
    );
  }

  String promptFor(String key) {
    switch (key) {
      case 'claim':
        return claimPrompt;
      case 'evidence':
        return evidencePrompt;
      case 'counter':
        return counterPrompt;
      case 'rebuttal':
        return rebuttalPrompt;
      default:
        return '';
    }
  }
}

class _ArgumentBuilderWidget extends StatefulWidget {
  final _ArgumentBuilderData data;
  final void Function(String section, String content) onReview;

  const _ArgumentBuilderWidget({required this.data, required this.onReview});

  @override
  State<_ArgumentBuilderWidget> createState() => _ArgumentBuilderWidgetState();
}

class _ArgumentBuilderWidgetState extends State<_ArgumentBuilderWidget>
    with SingleTickerProviderStateMixin {
  final _controllers = {
    'claim': TextEditingController(),
    'evidence': TextEditingController(),
    'counter': TextEditingController(),
    'rebuttal': TextEditingController(),
  };
  final _reviewed = <String>{};
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
    for (final c in _controllers.values) {
      c.dispose();
    }
    _ctrl.dispose();
    super.dispose();
  }

  void _requestReview(String key) {
    final text = _controllers[key]?.text ?? '';
    if (text.trim().isEmpty) return;
    setState(() => _reviewed.add(key));
    widget.onReview(key, text.trim());
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.data.topic,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Position: ${widget.data.position}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ..._sections.map((sec) => _buildSection(sec, theme, cs)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(_SectionConfig sec, ThemeData theme, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: sec.accent.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Text(
              sec.label.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: sec.accent,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Text(
              widget.data.promptFor(sec.key),
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _controllers[sec.key],
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Write your ${sec.label.toLowerCase()}...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: OutlinedButton(
              onPressed: () => _requestReview(sec.key),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color:
                      _reviewed.contains(sec.key) ? Colors.green : sec.accent,
                ),
                foregroundColor:
                    _reviewed.contains(sec.key) ? Colors.green : sec.accent,
              ),
              child: Text(
                _reviewed.contains(sec.key) ? 'Reviewed ✓' : 'Review this',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final argumentBuilderItem = CatalogItem(
  name: 'ArgumentBuilder',
  dataSchema: argumentBuilderSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _ArgumentBuilderData.fromJson(json);
    return _ArgumentBuilderWidget(
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
