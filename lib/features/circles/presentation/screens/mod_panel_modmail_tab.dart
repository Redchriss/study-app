import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ModPanelModmailTab extends ConsumerWidget {
  final String communitySlug;
  const ModPanelModmailTab({super.key, required this.communitySlug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Query(
      options: QueryOptions(
        document: gql(kModmailThreads),
        variables: {'communitySlug': communitySlug, 'archived': false},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return const Center(child: LoadingWidget());
        if (result.hasException) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48,
                    color: DesignTokens.error),
                const SizedBox(height: 12),
                Text(graphQLErrorMessage(result.exception),
                    style: const TextStyle(color: DesignTokens.textSecondary)),
                const SizedBox(height: 8),
                TextButton(
                    onPressed: () => refetch?.call(),
                    child: const Text('Retry')),
              ],
            ),
          );
        }
        final threads = (result.data?['modmailThreads'] as List?) ?? [];
        if (threads.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mail_outline_rounded,
                    size: 48, color: DesignTokens.textTertiary),
                SizedBox(height: 12),
                Text('No modmail threads',
                    style:
                        TextStyle(color: DesignTokens.textSecondary)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => refetch?.call(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: threads.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${threads.length} threads',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800)),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => _composeModmail(context, ref),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('New'),
                      ),
                    ],
                  ),
                );
              }
              final t = threads[i - 1] as Map<String, dynamic>;
              return _ModmailThreadCard(
                thread: t,
                communitySlug: communitySlug,
                onChanged: () => refetch?.call(),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _composeModmail(BuildContext context, WidgetRef ref) async {
    final subjectCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Modmail'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subjectCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                  labelText: 'Subject', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                  labelText: 'Message', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Send')),
        ],
      ),
    );
    if (result != true ||
        subjectCtrl.text.trim().isEmpty ||
        bodyCtrl.text.trim().isEmpty) return;

    final client = ref.read(graphqlClientProvider);
    await client.mutate(MutationOptions(
      document: gql(kSendModmail),
      variables: {
        'communitySlug': communitySlug,
        'subject': subjectCtrl.text.trim(),
        'body': bodyCtrl.text.trim(),
      },
    ));
  }
}

class _ModmailThreadCard extends ConsumerWidget {
  final Map<String, dynamic> thread;
  final String communitySlug;
  final VoidCallback onChanged;

  const _ModmailThreadCard({
    required this.thread,
    required this.communitySlug,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(thread['subject']?.toString() ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          _timeAgo(thread['lastUpdated']?.toString() ?? ''),
          style: const TextStyle(
              color: DesignTokens.textSecondary, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (thread['isArchived'] == true)
              const Icon(Icons.archive_rounded,
                  size: 18, color: DesignTokens.textTertiary),
            IconButton(
              icon: const Icon(Icons.archive_outlined, size: 18),
              onPressed: () => _archive(context, ref),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        onTap: () => _openThread(context, ref),
      ),
    );
  }

  void _openThread(BuildContext context, WidgetRef ref) {
    final client = ref.read(graphqlClientProvider);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: _ModmailThreadDetail(
          threadId: thread['id'].toString(),
          client: client,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    final client = ref.read(graphqlClientProvider);
    await client.mutate(MutationOptions(
      document: gql(kArchiveModmailThread),
      variables: {'threadId': thread['id']},
    ));
    onChanged();
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

class _ModmailThreadDetail extends StatefulWidget {
  final String threadId;
  final GraphQLClient client;
  final VoidCallback onChanged;

  const _ModmailThreadDetail({
    required this.threadId,
    required this.client,
    required this.onChanged,
  });

  @override
  State<_ModmailThreadDetail> createState() => _ModmailThreadDetailState();
}

class _ModmailThreadDetailState extends State<_ModmailThreadDetail> {
  final _replyCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(kModmailThread),
        variables: {'threadId': widget.threadId},
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return const SizedBox(
              height: 300, child: Center(child: LoadingWidget()));
        }
        final thread = result.data?['modmailThread'];
        if (thread == null) {
          return const SizedBox(
              height: 200, child: Center(child: Text('Thread not found')));
        }
        final messages = (thread['messages'] as List?) ?? [];
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(thread['subject']?.toString() ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: messages.isEmpty
                    ? const Center(child: Text('No messages'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (_, i) {
                          final m = messages[i] as Map<String, dynamic>;
                          final author =
                              m['author'] as Map<String, dynamic>?;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: m['isInternal'] == true
                                  ? DesignTokens.warning
                                      .withValues(alpha: 0.08)
                                  : DesignTokens.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                        'u/${author?['username'] ?? 'unknown'}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12)),
                                    if (m['isInternal'] == true) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: DesignTokens.warning
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text('INTERNAL',
                                            style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: DesignTokens.warning)),
                                      ),
                                    ],
                                    const Spacer(),
                                    Text(_timeAgo(
                                        m['createdAt']?.toString() ?? ''),
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: DesignTokens.textTertiary)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(m['body']?.toString() ?? '',
                                    style: const TextStyle(
                                        fontSize: 13, height: 1.4)),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const Divider(height: 1),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Reply as mod...',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.fromLTRB(12, 10, 12, 10),
                        ),
                        maxLines: 3,
                        minLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send_rounded),
                      onPressed: _sending ? null : () => _sendReply(refetch),
                      color: DesignTokens.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendReply(VoidCallback? refetch) async {
    final body = _replyCtrl.text.trim();
    if (body.isEmpty) return;
    setState(() => _sending = true);
    await widget.client.mutate(MutationOptions(
      document: gql(kReplyModmail),
      variables: {
        'threadId': widget.threadId,
        'body': body,
      },
    ));
    _replyCtrl.clear();
    setState(() => _sending = false);
    refetch?.call();
    widget.onChanged();
  }

  String _timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}
