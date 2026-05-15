import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';

class ScannerResultsScreen extends StatelessWidget {
  final Map<String, dynamic> sessionData;
  const ScannerResultsScreen({super.key, required this.sessionData});

  @override
  Widget build(BuildContext context) {
    final solutions = (sessionData['solutions'] as List?) ?? [];
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: dark ? DesignTokens.darkBackground : DesignTokens.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: dark ? DesignTokens.darkSurface : DesignTokens.surface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Solutions',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${solutions.length} question${solutions.length == 1 ? '' : 's'} solved',
                    style: theme.textTheme.labelSmall?.copyWith(color: DesignTokens.textSecondary),
                  ),
                ],
              ),
            ),
          ),

          if (solutions.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: DesignTokens.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.document_scanner_outlined, size: 40, color: DesignTokens.primary),
                    ),
                    const SizedBox(height: 16),
                    Text('No solutions found', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                      'Try scanning a clearer photo of your paper.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: DesignTokens.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Summary bar
            SliverToBoxAdapter(
              child: _SummaryBar(solutions: solutions, dark: dark),
            ),

            // Solution cards
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _SolutionCard(
                    solution: solutions[i] as Map<String, dynamic>,
                    index: i,
                    dark: dark,
                  ).animate(delay: (i * 60).ms).fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0),
                  childCount: solutions.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Summary bar ──────────────────────────────────────────────────────────────
class _SummaryBar extends StatelessWidget {
  final List solutions;
  final bool dark;

  const _SummaryBar({required this.solutions, required this.dark});

  @override
  Widget build(BuildContext context) {
    final total = solutions.length;
    final withAnswer = solutions.where((s) {
      final a = (s as Map<String, dynamic>)['answer'];
      return a != null && a != 'N/A' && (a as String).trim().isNotEmpty;
    }).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.primary.withValues(alpha: 0.12),
            DesignTokens.accent.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: DesignTokens.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: DesignTokens.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'AI solved $withAnswer of $total question${total == 1 ? '' : 's'}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: DesignTokens.primary),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: DesignTokens.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
            ),
            child: Text(
              '${((withAnswer / total) * 100).round()}%',
              style: const TextStyle(
                color: DesignTokens.success,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ─── Single solution card ─────────────────────────────────────────────────────
class _SolutionCard extends StatefulWidget {
  final Map<String, dynamic> solution;
  final int index;
  final bool dark;

  const _SolutionCard({required this.solution, required this.index, required this.dark});

  @override
  State<_SolutionCard> createState() => _SolutionCardState();
}

class _SolutionCardState extends State<_SolutionCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final sol = widget.solution;
    final theme = Theme.of(context);
    final steps = (sol['steps'] as List?) ?? [];
    final answer = sol['answer'] as String?;
    final hasAnswer = answer != null && answer.trim().isNotEmpty && answer != 'N/A';
    final qNum = sol['questionNumber']?.toString() ?? '${widget.index + 1}';
    final qText = sol['questionText'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: widget.dark ? DesignTokens.darkSurface : DesignTokens.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        border: Border.all(
          color: (widget.dark ? DesignTokens.darkBorder : DesignTokens.border).withValues(alpha: 0.6),
        ),
        boxShadow: DesignTokens.shadowSm(widget.dark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusXl)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Q number badge
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [DesignTokens.primary, DesignTokens.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    ),
                    child: Center(
                      child: Text(
                        'Q$qNum',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (qText.isNotEmpty)
                          Text(
                            qText,
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: _expanded ? null : 2,
                            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.format_list_numbered, size: 13, color: DesignTokens.textTertiary),
                            const SizedBox(width: 4),
                            Text(
                              '${steps.length} step${steps.length == 1 ? '' : 's'}',
                              style: theme.textTheme.labelSmall?.copyWith(color: DesignTokens.textTertiary),
                            ),
                            if (hasAnswer) ...[
                              const SizedBox(width: 10),
                              const Icon(Icons.check_circle, size: 13, color: DesignTokens.success),
                              const SizedBox(width: 4),
                              Text(
                                'Answer ready',
                                style: theme.textTheme.labelSmall?.copyWith(color: DesignTokens.success),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: DesignTokens.textTertiary,
                  ),
                ],
              ),
            ),
          ),

          if (_expanded) ...[
            const Divider(height: 1),
            // Steps
            if (steps.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.route_outlined, size: 14, color: DesignTokens.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Working',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: DesignTokens.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...steps.asMap().entries.map((e) => _StepRow(
                          stepNum: e.key + 1,
                          text: e.value?.toString() ?? '',
                          dark: widget.dark,
                        )),
                  ],
                ),
              ),

            // Answer box
            if (hasAnswer)
              _AnswerBox(answer: answer!, dark: widget.dark),

            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

// ─── Step row ─────────────────────────────────────────────────────────────────
class _StepRow extends StatelessWidget {
  final int stepNum;
  final String text;
  final bool dark;

  const _StepRow({required this.stepNum, required this.text, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number circle
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: DesignTokens.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: DesignTokens.primary.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                '$stepNum',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: MarkdownBody(
              data: text,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: dark ? DesignTokens.darkTextPrimary : DesignTokens.textPrimary,
                ),
                code: TextStyle(
                  fontSize: 13,
                  backgroundColor: dark
                      ? DesignTokens.darkSurfaceVariant
                      : DesignTokens.surfaceVariant,
                  color: DesignTokens.primary,
                  fontFamily: 'monospace',
                ),
                blockquoteDecoration: BoxDecoration(
                  border: Border(left: BorderSide(color: DesignTokens.accent, width: 3)),
                  color: DesignTokens.accent.withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Answer box ───────────────────────────────────────────────────────────────
class _AnswerBox extends StatelessWidget {
  final String answer;
  final bool dark;

  const _AnswerBox({required this.answer, required this.dark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignTokens.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: DesignTokens.success.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: DesignTokens.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Final Answer',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: DesignTokens.success,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                MarkdownBody(
                  data: answer,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: DesignTokens.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.copy_outlined, size: 16, color: DesignTokens.textTertiary),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: answer));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Answer copied'), duration: Duration(seconds: 1)),
              );
            },
          ),
        ],
      ),
    );
  }
}
