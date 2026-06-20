import 'package:flutter/material.dart';
import 'argument_builder_data.dart';

class ArgumentBuilderWidget extends StatefulWidget {
  final ArgumentBuilderData data;
  final void Function(String section, String content) onReview;

  const ArgumentBuilderWidget(
      {super.key, required this.data, required this.onReview});

  @override
  State<ArgumentBuilderWidget> createState() => _ArgumentBuilderWidgetState();
}

class _ArgumentBuilderWidgetState extends State<ArgumentBuilderWidget>
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
            ...argumentSections.map((sec) => _buildSection(sec, theme, cs)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(SectionConfig sec, ThemeData theme, ColorScheme cs) {
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
                _reviewed.contains(sec.key) ? 'Reviewed \u2713' : 'Review this',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
