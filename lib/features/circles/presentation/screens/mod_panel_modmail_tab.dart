import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import 'inbox_modmail_detail.dart';

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
            itemCount: threads.length,
            itemBuilder: (_, i) {
              final t = threads[i] as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(t['subject']?.toString() ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(t['community']?['name']?.toString() ?? '',
                      style: const TextStyle(
                          color: DesignTokens.textSecondary, fontSize: 12)),
                  trailing: t['isArchived'] == true
                      ? const Icon(Icons.archive_rounded,
                          size: 18, color: DesignTokens.textTertiary)
                      : null,
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      insetPadding: const EdgeInsets.all(16),
                      child: ModmailThreadDetail(threadId: t['id'].toString()),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
