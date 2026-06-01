import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

const String kModmailThreads = r'''query ModmailThreads { __typename }''';

class ModmailThreadList extends ConsumerWidget {
  final String communitySlug;
  final String communityName;

  const ModmailThreadList({
    super.key,
    required this.communitySlug,
    required this.communityName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('y/$communityName modmail',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'New modmail',
            onPressed: () => context.push(
              '/send-modmail',
              extra: {
                'communitySlug': communitySlug,
                'communityName': communityName
              },
            ),
          ),
        ],
      ),
      body: Query(
        options: QueryOptions(
          document: gql(kModmailThreads),
          variables: {'communitySlug': communitySlug},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
        builder: (result, {fetchMore, refetch}) {
          if (result.isLoading) return const Center(child: LoadingWidget());
          final threads = (result.data?['modmailThreads'] as List?) ?? [];
          if (threads.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mail_outline_rounded,
                        size: 64,
                        color:
                            DesignTokens.textTertiary.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    const Text('No modmail threads',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: DesignTokens.textSecondary)),
                    const SizedBox(height: 8),
                    Text(
                      'When users message the mod team, threads appear here.',
                      style: TextStyle(color: DesignTokens.textTertiary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.push(
                        '/send-modmail',
                        extra: {
                          'communitySlug': communitySlug,
                          'communityName': communityName
                        },
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('New thread'),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => refetch?.call(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: threads.length,
              itemBuilder: (_, i) {
                final t = threads[i] as Map<String, dynamic>;
                final messages = (t['messages'] as List?) ?? [];
                final lastMsg = messages.isNotEmpty
                    ? messages.last as Map<String, dynamic>
                    : null;
                final lastAuthor = lastMsg?['author'] as Map<String, dynamic>?;
                return _ModmailThreadTile(
                  thread: t,
                  lastMessageBody: lastMsg?['body']?.toString() ?? '',
                  lastAuthorName: lastAuthor?['username']?.toString(),
                  lastUpdated: t['lastUpdated']?.toString() ?? '',
                  isArchived: t['isArchived'] == true,
                  onTap: () => context.push(
                    '/modmail/${t['id']}',
                    extra: {
                      'threadId': t['id'].toString(),
                      'communitySlug': communitySlug,
                      'communityName': communityName,
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ModmailThreadTile extends StatelessWidget {
  final Map<String, dynamic> thread;
  final String lastMessageBody;
  final String? lastAuthorName;
  final String lastUpdated;
  final bool isArchived;
  final VoidCallback onTap;

  const _ModmailThreadTile({
    required this.thread,
    required this.lastMessageBody,
    this.lastAuthorName,
    required this.lastUpdated,
    required this.isArchived,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: dark ? DesignTokens.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isArchived
                ? DesignTokens.border.withValues(alpha: 0.3)
                : DesignTokens.primary.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: DesignTokens.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.mail_outline_rounded,
                  color: DesignTokens.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    thread['subject']?.toString() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (lastMessageBody.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      lastMessageBody,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (lastAuthorName != null) ...[
                        Text('u/$lastAuthorName',
                            style: const TextStyle(
                                fontSize: 11,
                                color: DesignTokens.textSecondary)),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: DesignTokens.textTertiary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(_timeAgo(lastUpdated),
                          style: const TextStyle(
                              fontSize: 11, color: DesignTokens.textTertiary)),
                    ],
                  ),
                ],
              ),
            ),
            if (isArchived)
              const Icon(Icons.archive_rounded,
                  size: 18, color: DesignTokens.textTertiary),
          ],
        ),
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
