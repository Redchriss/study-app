import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SendModmailScreen extends ConsumerStatefulWidget {
  const SendModmailScreen({super.key});

  @override
  ConsumerState<SendModmailScreen> createState() => _SendModmailScreenState();
}

class _SendModmailScreenState extends ConsumerState<SendModmailScreen> {
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _sending = false;

  String? get _communitySlug =>
      (ModalRoute.of(context)?.settings.arguments as Map?)?['communitySlug']
          as String?;

  String? get _communityName =>
      (ModalRoute.of(context)?.settings.arguments as Map?)?['communityName']
          as String?;

  Future<void> _send() async {
    final slug = _communitySlug;
    if (slug == null) return;
    final subject = _subjectCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (subject.isEmpty || body.isEmpty) return;

    setState(() => _sending = true);
    try {
      final client = ref.read(graphqlClientProvider);
      await client.mutate(MutationOptions(
        document: gql(kSendModmail),
        variables: {
          'communitySlug': slug,
          'subject': subject,
          'body': body,
        },
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message sent')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = _communityName ?? _communitySlug ?? 'community';
    return Scaffold(
      appBar: AppBar(
        title: const Text('New modmail',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To: y/$name moderators',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: _subjectCtrl,
              decoration: InputDecoration(
                labelText: 'Subject',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? DesignTokens.darkSurfaceVariant
                    : DesignTokens.surfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _bodyCtrl,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'Write your message...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? DesignTokens.darkSurfaceVariant
                      : DesignTokens.surfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _sending ? null : _send,
                child: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Send Message',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
