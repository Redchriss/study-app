import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../../core/graphql/queries/domain/community_queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'report_ban_dialog.dart';
import 'report_content_preview.dart';

class ReportQueueItem extends ConsumerWidget {
  final Map<String, dynamic> report;
  final String communitySlug;
  final VoidCallback onResolved;

  const ReportQueueItem({
    super.key,
    required this.report,
    required this.communitySlug,
    required this.onResolved,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final post = report['post'] as Map<String, dynamic>?;
    final comment = report['comment'] as Map<String, dynamic>?;
    final reporter = report['reporter'] as Map<String, dynamic>?;
    final createdAt = report['createdAt'] as String? ?? '';
    final reason = report['reason'] as String? ?? '';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: DesignTokens.error.withValues(alpha: 0.05),
            child: Row(
              children: [
                const Icon(Icons.flag_rounded,
                    size: 16, color: DesignTokens.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reported by u/${reporter?['username'] ?? 'unknown'}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: DesignTokens.textSecondary),
                  ),
                ),
                Text(
                  _timeAgo(createdAt),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: DesignTokens.textTertiary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Icon(
                  post != null
                      ? Icons.article_outlined
                      : Icons.comment_outlined,
                  size: 14,
                  color: DesignTokens.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    reason,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          if (post != null)
            ContentPreview(
                item: post, isPost: true, communitySlug: communitySlug),
          if (comment != null)
            ContentPreview(
                item: comment, isPost: false, communitySlug: communitySlug),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
            child: Row(
              children: [
                ActionChip(
                  icon: Icons.check_circle_outline,
                  label: 'Approve',
                  color: DesignTokens.success,
                  onTap: () => _approve(context, ref),
                ),
                ActionChip(
                  icon: Icons.delete_outline,
                  label: 'Remove',
                  color: DesignTokens.error,
                  onTap: () => _resolve(context, ref, 'REMOVE_CONTENT'),
                ),
                ActionChip(
                  icon: Icons.block,
                  label: 'Ban',
                  color: DesignTokens.error,
                  onTap: () => _banUser(context, ref, post),
                ),
                ActionChip(
                  icon: Icons.clear,
                  label: 'Ignore',
                  color: DesignTokens.textTertiary,
                  onTap: () => _resolve(context, ref, 'IGNORE'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resolve(
      BuildContext context, WidgetRef ref, String action) async {
    final client = ref.read(graphqlClientProvider);
    final result = await client.mutate(MutationOptions(
      document: gql(kResolveReport),
      variables: {'reportId': report['id'], 'action': action},
    ));
    if (result.hasException) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                result.exception?.graphqlErrors.first.message ?? 'Failed')));
      }
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(action == 'IGNORE' ? 'Report ignored' : 'Content removed')));
    }
    onResolved();
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final post = report['post'] as Map<String, dynamic>?;
    if (post == null) return;
    final client = ref.read(graphqlClientProvider);
    final result = await client.mutate(MutationOptions(
      document: gql(kApprovePost),
      variables: {'postId': post['id']},
    ));
    if (result.hasException) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                result.exception?.graphqlErrors.first.message ?? 'Failed')));
      }
      return;
    }
    _resolve(context, ref, 'IGNORE');
  }

  Future<void> _banUser(
      BuildContext context, WidgetRef ref, Map<String, dynamic>? post) async {
    final author = post?['author'] as Map<String, dynamic>?;
    final username = author?['username']?.toString();
    if (username == null || username.isEmpty) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => BanUserDialog(username: username),
    );
    if (result == null) return;
    final reason = result['reason'] as String;
    if (reason.trim().isEmpty) return;
    final isPermanent = result['isPermanent'] as bool;
    final durationDays = result['durationDays'] as int;
    final client = ref.read(graphqlClientProvider);
    final mutationResult = await client.mutate(MutationOptions(
      document: gql(kBanUser),
      variables: {
        'communitySlug': communitySlug,
        'username': username,
        'reason': reason.trim(),
        'isPermanent': isPermanent,
        if (!isPermanent) 'durationDays': durationDays,
      },
    ));
    if (mutationResult.hasException) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                mutationResult.exception?.graphqlErrors.first.message ??
                    'Failed')));
      }
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('u/$username has been banned')));
    }
    onResolved();
  }

  String _timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${diff.inDays ~/ 7}w ago';
    } catch (_) {
      return '';
    }
  }
}

class ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ActionChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
