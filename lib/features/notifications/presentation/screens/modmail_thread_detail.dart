import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'modmail_message_bubble.dart';
import 'modmail_reply_input.dart';

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
                          return ModmailMessageBubble(message: m, dark: dark);
                        },
                      ),
              ),
              ModmailReplyInput(
                isInternal: _isInternal,
                isSending: _sending,
                onToggleInternal: () =>
                    setState(() => _isInternal = !_isInternal),
                controller: _msgCtrl,
                onSend: _sendMessage,
              ),
            ],
          );
        },
      ),
    );
  }
}
