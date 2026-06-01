import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import 'inbox_modmail_detail.dart';

class InboxModmailTab extends ConsumerWidget {
  const InboxModmailTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Query(
      options: QueryOptions(document: gql(kMyCommunities)),
      builder: (result, {fetchMore, refetch}) {
        final communities = (result.data?['myCommunities'] as List?) ?? [];
        if (result.isLoading) return const Center(child: LoadingWidget());
        if (communities.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Join a community to access modmail',
                  style: TextStyle(color: DesignTokens.textSecondary)),
            ),
          );
        }
        return _ModmailCommunityList(
            communities: communities.cast<Map<String, dynamic>>());
      },
    );
  }
}

class _ModmailCommunityList extends StatelessWidget {
  final List<Map<String, dynamic>> communities;
  const _ModmailCommunityList({required this.communities});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: communities.length,
      itemBuilder: (_, i) {
        final c = communities[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: DesignTokens.primary.withValues(alpha: 0.1),
              child: const Icon(Icons.mail_outline_rounded,
                  color: DesignTokens.primary, size: 20),
            ),
            title: Text('y/${c['name']}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${c['memberCount']} members',
                style: const TextStyle(
                    color: DesignTokens.textSecondary, fontSize: 12)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _openThreadList(context, c['slug'].toString()),
          ),
        );
      },
    );
  }

  void _openThreadList(BuildContext context, String slug) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        builder: (_, scrollCtrl) => _ModmailThreadList(communitySlug: slug),
      ),
    );
  }
}

class _ModmailThreadList extends StatelessWidget {
  final String communitySlug;
  const _ModmailThreadList({required this.communitySlug});

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(kModmailThreads),
        variables: {'communitySlug': communitySlug},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return const Center(child: LoadingWidget());
        final threads = (result.data?['modmailThreads'] as List?) ?? [];
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                      child: Text('y/$communitySlug modmail',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 18))),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () => refetch?.call(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (threads.isEmpty)
              const Expanded(
                child: Center(
                    child: Text('No modmail threads',
                        style: TextStyle(color: DesignTokens.textSecondary))),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: threads.length,
                  itemBuilder: (_, i) {
                    final t = threads[i] as Map<String, dynamic>;
                    return ListTile(
                      title: Text(t['subject']?.toString() ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          _timeAgo(t['lastUpdated']?.toString() ?? ''),
                          style: const TextStyle(
                              color: DesignTokens.textSecondary, fontSize: 12)),
                      trailing: t['isArchived'] == true
                          ? const Icon(Icons.archive_rounded,
                              size: 18, color: DesignTokens.textTertiary)
                          : null,
                      onTap: () =>
                          _showThreadDetail(context, t['id'].toString()),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  void _showThreadDetail(BuildContext context, String threadId) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ModmailThreadDetail(threadId: threadId),
      ),
    );
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
