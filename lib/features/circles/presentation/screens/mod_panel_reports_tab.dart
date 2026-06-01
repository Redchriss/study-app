import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/graphql/queries/domain/community_queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ModPanelReportsTab extends ConsumerWidget {
  final String communitySlug;

  const ModPanelReportsTab({super.key, required this.communitySlug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Query(
      options: QueryOptions(
        document: gql(kReportsQuery),
        variables: {'communitySlug': communitySlug, 'status': 'pending'},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (result.hasException) {
          return ErrorState(
            message: result.exception?.graphqlErrors.first.message ??
                'Failed to load reports',
            onRetry: () => refetch?.call(),
          );
        }
        final reports = result.data?['reports'] as List<dynamic>? ?? [];
        if (reports.isEmpty) {
          return ListView(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.3),
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.shield_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No pending reports',
                        style: TextStyle(fontSize: 18, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text('Your community is looking good!',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          );
        }
        return RefreshIndicator(
          onRefresh: () async => refetch?.call(),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = reports[i] as Map<String, dynamic>;
              return _ReportQueueItem(
                report: r,
                communitySlug: communitySlug,
                onResolved: () => refetch?.call(),
              );
            },
          ),
        );
      },
    );
  }
}

class _ReportQueueItem extends ConsumerWidget {
  final Map<String, dynamic> report;
  final String communitySlug;
  final VoidCallback onResolved;

  const _ReportQueueItem({
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
          if (post != null) _contentPreview(context, post, isPost: true),
          if (comment != null) _contentPreview(context, comment, isPost: false),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
            child: Row(
              children: [
                _ActionChip(
                  icon: Icons.check_circle_outline,
                  label: 'Approve',
                  color: DesignTokens.success,
                  onTap: () => _approve(context, ref),
                ),
                _ActionChip(
                  icon: Icons.delete_outline,
                  label: 'Remove',
                  color: DesignTokens.error,
                  onTap: () => _resolve(context, ref, 'REMOVE_CONTENT'),
                ),
                _ActionChip(
                  icon: Icons.block,
                  label: 'Ban',
                  color: DesignTokens.error,
                  onTap: () => _banUser(context, ref, post),
                ),
                _ActionChip(
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

  Widget _contentPreview(BuildContext context, Map<String, dynamic> item,
      {required bool isPost}) {
    final content =
        isPost ? item['title']?.toString() : item['body']?.toString();
    final author =
        (item['author'] as Map<String, dynamic>?)?['username']?.toString();
    final icon = isPost ? Icons.article_outlined : Icons.comment_outlined;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: InkWell(
        onTap: isPost
            ? () => context.push('/y/$communitySlug/post/${item['slug']}')
            : null,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: DesignTokens.surfaceVariant,
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: DesignTokens.textTertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (content != null)
                      Text(
                        content,
                        maxLines: isPost ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    if (author != null)
                      Text(
                        'u/$author',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DesignTokens.textTertiary, fontSize: 11),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

    final reasonCtrl = TextEditingController();
    final isPermanent = ValueNotifier<bool>(true);
    final durationDays = ValueNotifier<int>(7);

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ban u/$username'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: reasonCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Reason for ban',
                labelText: 'Ban reason',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<bool>(
              valueListenable: isPermanent,
              builder: (_, perm, __) => SwitchListTile(
                title: const Text('Permanent ban'),
                value: perm,
                onChanged: (v) => isPermanent.value = v,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (!isPermanent.value)
              ValueListenableBuilder<int>(
                valueListenable: durationDays,
                builder: (_, days, __) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Duration', style: TextStyle(fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [3, 7, 14, 30].map((d) {
                        final selected = days == d;
                        return ChoiceChip(
                          label: Text('$d days'),
                          selected: selected,
                          onSelected: (_) => durationDays.value = d,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm Ban')),
        ],
      ),
    );
    if (proceed != true || reasonCtrl.text.trim().isEmpty) return;

    final client = ref.read(graphqlClientProvider);
    final result = await client.mutate(MutationOptions(
      document: gql(kBanUser),
      variables: {
        'communitySlug': communitySlug,
        'username': username,
        'reason': reasonCtrl.text.trim(),
        'isPermanent': isPermanent.value,
        if (!isPermanent.value) 'durationDays': durationDays.value,
      },
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

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
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
