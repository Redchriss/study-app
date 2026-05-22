import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import 'scanner_results_step_row.dart';
import 'scanner_results_answer_box.dart';

class ScannerResultsSolutionCard extends StatefulWidget {
  final Map<String, dynamic> solution;
  final int index;
  final bool dark;

  const ScannerResultsSolutionCard(
      {super.key,
      required this.solution,
      required this.index,
      required this.dark});

  @override
  State<ScannerResultsSolutionCard> createState() =>
      _ScannerResultsSolutionCardState();
}

class _ScannerResultsSolutionCardState
    extends State<ScannerResultsSolutionCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final sol = widget.solution;
    final theme = Theme.of(context);
    final steps = (sol['steps'] as List?) ?? [];
    final answer = sol['answer'] as String?;
    final hasAnswer =
        answer != null && answer.trim().isNotEmpty && answer != 'N/A';
    final qNum = sol['questionNumber']?.toString() ?? '${widget.index + 1}';
    final qText = sol['questionText'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: widget.dark ? DesignTokens.darkSurface : DesignTokens.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        border: Border.all(
            color: (widget.dark ? DesignTokens.darkBorder : DesignTokens.border)
                .withValues(alpha: 0.6)),
        boxShadow: DesignTokens.shadowSm(widget.dark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(DesignTokens.radiusXl)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        DesignTokens.primary,
                        DesignTokens.primaryLight
                      ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusMd),
                    ),
                    child: Center(
                        child: Text('Q$qNum',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (qText.isNotEmpty)
                          Text(qText,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: _expanded ? null : 2,
                              overflow: _expanded
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(children: [
                          Icon(Icons.format_list_numbered,
                              size: 13, color: DesignTokens.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                              '${steps.length} step${steps.length == 1 ? '' : 's'}',
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: DesignTokens.textTertiary)),
                          if (hasAnswer) ...[
                            const SizedBox(width: 10),
                            const Icon(Icons.check_circle,
                                size: 13, color: DesignTokens.success),
                            const SizedBox(width: 4),
                            Text('Answer ready',
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(color: DesignTokens.success))
                          ],
                        ]),
                      ],
                    ),
                  ),
                  Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: DesignTokens.textTertiary),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            if (steps.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.route_outlined,
                          size: 14, color: DesignTokens.primary),
                      const SizedBox(width: 6),
                      Text('Working',
                          style: theme.textTheme.labelMedium?.copyWith(
                              color: DesignTokens.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4))
                    ]),
                    const SizedBox(height: 10),
                    ...steps.asMap().entries.map((e) => ScannerResultsStepRow(
                        stepNum: e.key + 1,
                        text: e.value?.toString() ?? '',
                        dark: widget.dark)),
                  ],
                ),
              ),
            if (hasAnswer)
              ScannerResultsAnswerBox(answer: answer!, dark: widget.dark),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
