import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class DashboardFocusCoachCard extends StatelessWidget {
  final List<String> weakestTopics;
  final List<String> strongestTopics;
  final List<String> strugglingTopics;
  final List<String> masteredTopics;

  const DashboardFocusCoachCard({
    super.key,
    required this.weakestTopics,
    required this.strongestTopics,
    required this.strugglingTopics,
    required this.masteredTopics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final focusTopic =
        (weakestTopics.isNotEmpty ? weakestTopics : strugglingTopics)
            .firstOrNull;
    final confidenceTopic =
        (masteredTopics.isNotEmpty ? masteredTopics : strongestTopics)
            .firstOrNull;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DesignTokens.spMd, 0, DesignTokens.spMd, DesignTokens.spMd),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.psychology_alt_rounded,
                      color: Color(0xFF7C4DFF), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Memory Coach',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      Text(
                          focusTopic != null
                              ? 'Revise your weakest areas faster.'
                              : 'Plan your next study session.',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: DesignTokens.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            if (focusTopic != null || confidenceTopic != null) ...[
              const SizedBox(height: 14),
              if (focusTopic != null)
                _TopicRow(
                    icon: Icons.flag_rounded,
                    color: DesignTokens.warning,
                    title: 'Focus next',
                    text: focusTopic),
              if (confidenceTopic != null) ...[
                const SizedBox(height: 8),
                _TopicRow(
                    icon: Icons.workspace_premium_rounded,
                    color: DesignTokens.success,
                    title: 'Strong in',
                    text: confidenceTopic),
              ],
            ],
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CoachChip(
                      icon: Icons.psychology_alt_outlined,
                      label: focusTopic == null
                          ? 'Open coach'
                          : 'Memorize $focusTopic',
                      onTap: () => context.push('/ai-tutor')),
                  const SizedBox(width: 8),
                  _CoachChip(
                      icon: Icons.quiz_outlined,
                      label: focusTopic == null
                          ? 'Quiz me'
                          : 'Quiz on $focusTopic',
                      onTap: () => context.push('/ai-tutor')),
                  const SizedBox(width: 8),
                  _CoachChip(
                      icon: Icons.event_note_outlined,
                      label: 'Plan tonight',
                      onTap: () => context.push('/ai-tutor')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String text;
  const _TopicRow(
      {required this.icon,
      required this.color,
      required this.title,
      required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text('$title: ',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13, color: DesignTokens.textSecondary))),
      ],
    );
  }
}

class _CoachChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _CoachChip(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
