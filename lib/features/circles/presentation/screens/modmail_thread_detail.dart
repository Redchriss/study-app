import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class ModmailThreadDetail extends StatefulWidget {
  final String threadId;
  final GraphQLClient client;
  final VoidCallback onChanged;

  const ModmailThreadDetail({
    super.key,
    required this.threadId,
    required this.client,
    required this.onChanged,
  });

  @override
  State<ModmailThreadDetail> createState() => _ModmailThreadDetailState();
}

class _ModmailThreadDetailState extends State<ModmailThreadDetail> {
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
                          final author = m['author'] as Map<String, dynamic>?;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: m['isInternal'] == true
                                ? BoxDecoration(
                                    color: DesignTokens.warning
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  )
                                : DesignTokens.signatureSurface(
                                    Theme.of(context).brightness ==
                                        Brightness.dark,
                                    radius: 12),
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
                                    Text(
                                        _timeAgo(
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
