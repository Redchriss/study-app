import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'quiz_community_share_sheet.dart';

void showQuizShareSheet(
    BuildContext context, Map<String, dynamic>? attempt, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => _QuizShareSheet(attempt: attempt, ref: ref),
  );
}

class _QuizShareSheet extends ConsumerWidget {
  final Map<String, dynamic>? attempt;
  final WidgetRef ref;
  const _QuizShareSheet({required this.attempt, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef innerRef) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final quizTitle = attempt?['quiz']?['title']?.toString() ?? 'Quiz';
    final score = (attempt?['score'] as num?)?.toStringAsFixed(0) ?? '0';
    final correct = (attempt?['correctCount'] as num?)?.toInt() ?? 0;
    final total = (attempt?['totalPoints'] as num?)?.toInt() ?? correct;
    final pct = total > 0 ? (correct / total).clamp(0.0, 1.0) : 0.0;
    final username =
        innerRef.read(authProvider).user?['username']?.toString() ?? 'Student';

    final gradeEmoji = pct >= 0.9
        ? '🏆'
        : pct >= 0.7
            ? '👍'
            : pct >= 0.5
                ? '💪'
                : '📚';
    final gradeLabel = pct >= 0.9
        ? 'Excellent!'
        : pct >= 0.7
            ? 'Good job!'
            : pct >= 0.5
                ? 'Keep going!'
                : 'Keep studying!';
    final gradeColor = pct >= 0.9
        ? DesignTokens.success
        : pct >= 0.7
            ? DesignTokens.primary
            : pct >= 0.5
                ? DesignTokens.warning
                : DesignTokens.error;

    final shareText =
        '$gradeEmoji I scored $score% on "$quizTitle" ($correct/$total correct) on Yaza! $gradeLabel\n'
        '📲 Study smarter at yaza.app';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: DesignTokens.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            // Result card preview
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    gradeColor.withValues(alpha: 0.12),
                    gradeColor.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: gradeColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(gradeEmoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text(
                    '$score%',
                    style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: gradeColor,
                        height: 1),
                  ),
                  Text(gradeLabel,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: gradeColor)),
                  const SizedBox(height: 8),
                  Text(quizTitle,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('$correct of $total correct · @$username',
                      style: const TextStyle(
                          fontSize: 12, color: DesignTokens.textSecondary)),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: DesignTokens.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('yaza.app',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: DesignTokens.primary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Share via WhatsApp / any app
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Share.share(shareText, subject: 'My Yaza quiz result');
                },
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share Result',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Share to Circles community
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _shareToCircles(context, quizTitle, score, ref);
                },
                icon: const Icon(Icons.groups_outlined, size: 18),
                label: const Text('Share to Circles'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareToCircles(
      BuildContext context, String quizTitle, String score, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) =>
          QuizCommunityShareSheet(quizTitle: quizTitle, score: score, ref: ref),
    );
  }
}
