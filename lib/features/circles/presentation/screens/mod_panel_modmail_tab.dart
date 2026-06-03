import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'modmail_thread_card.dart';

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
                const Icon(Icons.error_outline,
                    size: 48, color: DesignTokens.error),
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
                    style: TextStyle(color: DesignTokens.textSecondary)),
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
              return ModmailThreadCard(
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
