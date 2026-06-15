import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class DashboardNextAction extends ConsumerWidget {
  const DashboardNextAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Query(
      options: QueryOptions(
        document: gql(kNextAction),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {refetch, fetchMore}) {
        if (result.isLoading) return const SizedBox.shrink();
        if (result.hasException) return const SizedBox.shrink();

        final data = result.data?['nextAction'] as Map<String, dynamic>?;
        if (data == null) return const SizedBox.shrink();

        final type = data['actionType'] as String? ?? '';
        final reason = data['reason'] as String? ?? '';
        final conceptName = data['conceptName'] as String?;
        final conceptSlug = data['conceptSlug'] as String?;
        final subjectCode = data['subjectCode'] as String?;
        final strategy = data['teachingStrategy'] as String?;

        if (type.isEmpty) return const SizedBox.shrink();

        // Determine icon and color
        IconData icon;
        Color color;
        String actionLabel;
        VoidCallback? onTap;

        switch (type) {
          case 'review':
            icon = Icons.schedule_rounded;
            color = DesignTokens.warning;
            actionLabel = 'Review Now';
            onTap = conceptSlug != null
                ? () => context.push('/ai-tutor', extra: {
                      'prompt': 'Review $conceptName',
                    })
                : null;
            break;
          case 'diagnose':
            icon = Icons.document_scanner_rounded;
            color = DesignTokens.secondary;
            actionLabel = 'Diagnose';
            onTap = () => context.push(
                  '/diagnostic/${subjectCode ?? 'MATH-S'}',
                );
            break;
          case 'teach':
            icon = Icons.school_rounded;
            color = DesignTokens.primary;
            actionLabel = strategy != null
                ? 'Learn (${strategy.replaceAll('_', ' ')})'
                : 'Start Learning';
            onTap = conceptSlug != null
                ? () => context.push('/ai-tutor', extra: {
                      'prompt': 'Teach me $conceptName',
                    })
                : null;
            break;
          case 'practice':
            icon = Icons.quiz_rounded;
            color = DesignTokens.accent;
            actionLabel = 'Practice';
            onTap = null;
            break;
          case 'challenge':
            icon = Icons.rocket_launch_rounded;
            color = DesignTokens.success;
            actionLabel = 'Challenge';
            onTap = null;
            break;
          default:
            icon = Icons.auto_stories_rounded;
            color = DesignTokens.primary;
            actionLabel = 'Study';
            onTap = null;
        }

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
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type == 'review'
                                ? '📅 Review Due'
                                : type == 'diagnose'
                                    ? '🔍 Knowledge Check'
                                    : type == 'teach'
                                        ? '📖 Ready to Learn'
                                        : '🎯 Your Next Step',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            reason.length > 80
                                ? '${reason.substring(0, 80)}...'
                                : reason,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: DesignTokens.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (onTap != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onTap,
                      icon: Icon(icon, size: 18),
                      label: Text(actionLabel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color.withValues(alpha: 0.15),
                        foregroundColor: color,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: color.withValues(alpha: 0.3)),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
      },
    );
  }
}
