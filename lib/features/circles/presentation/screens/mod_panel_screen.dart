import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../../core/graphql/graphql_client_provider.dart';
import '../../../../core/graphql/queries/domain/community_queries.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/shimmer_box.dart';

class ModPanelScreen extends ConsumerWidget {
  final String communitySlug;

  const ModPanelScreen({super.key, required this.communitySlug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('y/$communitySlug mod'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Reports', icon: Icon(Icons.flag_outlined)),
              Tab(text: 'Mod Log', icon: Icon(Icons.history)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ReportsTab(communitySlug: communitySlug),
            _ModLogTab(communitySlug: communitySlug),
          ],
        ),
      ),
    );
  }
}

class _ReportsTab extends ConsumerWidget {
  final String communitySlug;

  const _ReportsTab({required this.communitySlug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.read(graphqlClientProvider);
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
            message: result.exception?.graphqlErrors.first.message ?? 'Failed to load reports',
            onRetry: () => refetch?.call(),
          );
        }
        final reports = result.data?['reports'] as List<dynamic>? ?? [];
        if (reports.isEmpty) {
          return ListView(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.3,
              ),
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.shield_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No pending reports', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text('Your community is looking good!', style: TextStyle(color: Colors.grey)),
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
              return _ReportCard(
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

class _ReportCard extends ConsumerWidget {
  final Map<String, dynamic> report;
  final String communitySlug;
  final VoidCallback onResolved;

  const _ReportCard({
    required this.report,
    required this.communitySlug,
    required this.onResolved,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final post = report['post'] as Map<String, dynamic>?;
    final comment = report['comment'] as Map<String, dynamic>?;
    final reporter = report['reporter'] as Map<String, dynamic>?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag, size: 16, color: Colors.red),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Reported by u/${reporter?['username'] ?? 'unknown'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(report['reason'] as String? ?? '', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            if (post != null)
              InkWell(
                onTap: () => context.push('/y/$communitySlug/post/${post['slug']}'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.article_outlined, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          post['title'] as String? ?? '',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (comment != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.comment_outlined, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        comment['body'] as String? ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _resolve(context, ref, 'IGNORE'),
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Ignore'),
                ),
                const SizedBox(width: 4),
                FilledButton.tonal.icon(
                  onPressed: () => _resolve(context, ref, 'REMOVE_CONTENT'),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Remove'),
                  style: FilledButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resolve(BuildContext context, WidgetRef ref, String action) async {
    final client = ref.read(graphqlClientProvider);
    final result = await client.mutate(
      MutationOptions(
        document: gql(kResolveReport),
        variables: {
          'reportId': report['id'],
          'action': action,
        },
      ),
    );
    if (result.hasException) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.exception?.graphqlErrors.first.message ?? 'Failed')),
        );
      }
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(action == 'IGNORE' ? 'Report ignored' : 'Content removed')),
      );
    }
    onResolved();
  }
}

class _ModLogTab extends ConsumerWidget {
  final String communitySlug;

  const _ModLogTab({required this.communitySlug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Query(
      options: QueryOptions(
        document: gql(kModLogQuery),
        variables: {'communitySlug': communitySlug},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (result.hasException) {
          return ErrorState(
            message: result.exception?.graphqlErrors.first.message ?? 'Failed to load mod log',
            onRetry: () => refetch?.call(),
          );
        }
        final entries = result.data?['modLog'] as List<dynamic>? ?? [];
        if (entries.isEmpty) {
          return ListView(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.3),
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No moderation actions yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
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
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final e = entries[i] as Map<String, dynamic>;
              return _ModLogTile(entry: e, communitySlug: communitySlug);
            },
          ),
        );
      },
    );
  }
}

class _ModLogTile extends StatelessWidget {
  final Map<String, dynamic> entry;
  final String communitySlug;

  const _ModLogTile({required this.entry, required this.communitySlug});

  IconData _iconForAction(String action) {
    switch (action) {
      case 'remove_post':
      case 'remove_comment':
        return Icons.delete_outline;
      case 'ban_user':
        return Icons.block;
      case 'unban_user':
        return Icons.person_add_alt;
      case 'approve_post':
        return Icons.check_circle_outline;
      case 'pin_post':
        return Icons.push_pin_outlined;
      case 'lock_post':
        return Icons.lock_outline;
      case 'add_mod':
        return Icons.admin_panel_settings_outlined;
      case 'remove_mod':
        return Icons.remove_moderator_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = entry['action'] as String? ?? '';
    final moderator = entry['moderator'] as Map<String, dynamic>?;
    final targetUser = entry['targetUser'] as Map<String, dynamic>?;
    final post = entry['post'] as Map<String, dynamic>?;
    final createdAt = entry['createdAt'] as String? ?? '';

    return ListTile(
      leading: Icon(_iconForAction(action), size: 20),
      title: Text(
        action.replaceAll('_', ' '),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          'by u/${moderator?['username'] ?? 'unknown'}',
          if (targetUser != null) '→ u/${targetUser['username']}',
          if (post != null) 'on "${post['title']}"',
        ].join(' '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        _formatTime(createdAt),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}
