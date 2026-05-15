import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';

class AiTutorPreferencesSheet extends StatefulWidget {
  const AiTutorPreferencesSheet({
    super.key,
    required this.initialLearningStyle,
    required this.initialPrefersExamples,
    required this.initialPrefersStepByStep,
    required this.initialDetailLevel,
    required this.onSave,
    this.saving = false,
  });

  final String initialLearningStyle;
  final bool initialPrefersExamples;
  final bool initialPrefersStepByStep;
  final int initialDetailLevel;
  final bool saving;
  final Future<void> Function({
    required String learningStyle,
    required bool prefersExamples,
    required bool prefersStepByStep,
    required int detailLevel,
  }) onSave;

  @override
  State<AiTutorPreferencesSheet> createState() => _AiTutorPreferencesSheetState();
}

class _AiTutorPreferencesSheetState extends State<AiTutorPreferencesSheet> {
  late String _learningStyle;
  late bool _prefersExamples;
  late bool _prefersStepByStep;
  late int _detailLevel;

  @override
  void initState() {
    super.initState();
    _learningStyle = widget.initialLearningStyle;
    _prefersExamples = widget.initialPrefersExamples;
    _prefersStepByStep = widget.initialPrefersStepByStep;
    _detailLevel = widget.initialDetailLevel;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tutor Preferences',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.saving ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Shape how the tutor explains, quizzes, and revises for you.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: DesignTokens.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Learning style',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                ('mixed', 'Mixed'),
                ('visual', 'Visual'),
                ('reading', 'Reading'),
                ('kinesthetic', 'Practical'),
              ].map((option) {
                final selected = option.$1 == _learningStyle;
                return ChoiceChip(
                  label: Text(option.$2),
                  selected: selected,
                  onSelected: widget.saving
                      ? null
                      : (_) => setState(() => _learningStyle = option.$1),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'Response depth',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment<int>(value: 1, label: Text('Short')),
                ButtonSegment<int>(value: 2, label: Text('Balanced')),
                ButtonSegment<int>(value: 3, label: Text('Deep')),
              ],
              selected: <int>{_detailLevel},
              onSelectionChanged: widget.saving
                  ? null
                  : (values) => setState(() => _detailLevel = values.first),
            ),
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              value: _prefersStepByStep,
              contentPadding: EdgeInsets.zero,
              onChanged: widget.saving
                  ? null
                  : (value) => setState(() => _prefersStepByStep = value),
              title: const Text('Prefer step-by-step explanations'),
              subtitle: const Text('Useful for solving and working through unfamiliar topics.'),
            ),
            SwitchListTile.adaptive(
              value: _prefersExamples,
              contentPadding: EdgeInsets.zero,
              onChanged: widget.saving
                  ? null
                  : (value) => setState(() => _prefersExamples = value),
              title: const Text('Prefer worked examples'),
              subtitle: const Text('Adds examples and concrete illustrations more often.'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: widget.saving
                    ? null
                    : () async {
                        await widget.onSave(
                          learningStyle: _learningStyle,
                          prefersExamples: _prefersExamples,
                          prefersStepByStep: _prefersStepByStep,
                          detailLevel: _detailLevel,
                        );
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                icon: widget.saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.tune),
                label: Text(widget.saving ? 'Saving...' : 'Save tutor preferences'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
