import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'modmail_thread_detail.dart';

class ModmailThreadCard extends ConsumerWidget {
  final Map<String, dynamic> thread;
  final String communitySlug;
  final VoidCallback onChanged;

  const ModmailThreadCard({
    super.key,
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
          style:
              const TextStyle(color: DesignTokens.textSecondary, fontSize: 12),
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
        child: ModmailThreadDetail(
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
