import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ModmailThreadDetail extends ConsumerStatefulWidget {
  final String threadId;
  final String communitySlug;
  final String communityName;

  const ModmailThreadDetail({
    super.key,
    required this.threadId,
    required this.communitySlug,
    required this.communityName,
  });

  @override
  ConsumerState<ModmailThreadDetail> createState() =>
      _ModmailThreadDetailState();
}

class _ModmailThreadDetailState extends ConsumerState<ModmailThreadDetail> {
  final TextEditingController _msgCtrl = TextEditingController();
  bool _isInternal = false;
  bool _sending = false;

  Future<void> _sendMessage() async {
    final body = _msgCtrl.text.trim();
    if (body.isEmpty) return;
    setState(() => _sending = true);
    try {
      final client = ref.read(graphqlClientProvider);
      await client.mutate(MutationOptions(
        document: gql(kReplyModmail),
        variables: {
          'threadId': widget.threadId,
          'body': body,
          'isInternal': _isInternal,
        },
      ));
      _msgCtrl.clear();
      if (mounted) setState(() => _sending = false);
    } catch (_) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
      }
    }
  }

  Future<void> _archiveThread() async {
    final client = ref.read(graphqlClientProvider);
    await client.mutate(MutationOptions(
      document: gql(kArchiveModmailThread),
      variables: {'threadId': widget.threadId},
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thread archived')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Modmail',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            Text('y/${widget.communityName}',
                style: const TextStyle(
                    fontSize: 12, color: DesignTokens.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            tooltip: 'Archive thread',
            onPressed: _archiveThread,
          ),
        ],
      ),
      body: Query(
        options: QueryOptions(
          document: gql(kModmailThread),
          variables: {'threadId': widget.threadId},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
        builder: (result, {fetchMore, refetch}) {
          if (result.isLoading) return const Center(child: LoadingWidget());

          final thread = result.data?['modmailThread'];
          if (thread == null) {
            return const Center(child: Text('Thread not found'));
          }

          final messages = (thread['messages'] as List?) ?? [];
          final subject = thread['subject']?.toString() ?? '';

          return Column(
            children: [
              if (subject.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: dark
                        ? DesignTokens.darkSurfaceVariant
                        : DesignTokens.surfaceVariant,
                    border: Border(
                      bottom: BorderSide(
                        color: dark
                            ? DesignTokens.darkBorder
                            : DesignTokens.border,
                      ),
                    ),
                  ),
                  child: Text(subject,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              Expanded(
                child: messages.isEmpty
                    ? const Center(
                        child: Text('No messages',
                            style:
                                TextStyle(color: DesignTokens.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        itemCount: messages.length,
                        itemBuilder: (_, i) {
                          final m = messages[i] as Map<String, dynamic>;
                          final author = m['author'] as Map<String, dynamic>?;
                          final isInternal = m['isInternal'] == true;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isInternal
                                  ? DesignTokens.warning.withValues(alpha: 0.08)
                                  : (dark
                                      ? DesignTokens.darkSurface
                                      : Colors.white),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isInternal
                                    ? DesignTokens.warning
                                        .withValues(alpha: 0.2)
                                    : (dark
                                        ? DesignTokens.darkBorder
                                        : DesignTokens.border),
                              ),
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
                                            fontSize: 13)),
                                    if (isInternal) ...[
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
                                const SizedBox(height: 8),
                                Text(m['body']?.toString() ?? '',
                                    style: const TextStyle(
                                        fontSize: 14, height: 1.4)),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: dark ? DesignTokens.darkSurfaceVariant : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color:
                          dark ? DesignTokens.darkBorder : DesignTokens.border,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () =>
                              setState(() => _isInternal = !_isInternal),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _isInternal
                                  ? DesignTokens.warning.withValues(alpha: 0.15)
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.shield_outlined,
                              size: 20,
                              color: _isInternal
                                  ? DesignTokens.warning
                                  : DesignTokens.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _msgCtrl,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                            decoration: InputDecoration(
                              hintText: _isInternal
                                  ? 'Internal note (mods only)'
                                  : 'Reply...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: dark
                                  ? DesignTokens.darkSurface
                                  : DesignTokens.surfaceVariant,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send_rounded),
                          color: DesignTokens.primary,
                          onPressed: _sending ? null : _sendMessage,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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
