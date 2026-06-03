import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../../core/graphql/queries/domain/community_queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class RulesSection extends ConsumerStatefulWidget {
  final String communitySlug;
  const RulesSection({super.key, required this.communitySlug});

  @override
  ConsumerState<RulesSection> createState() => _RulesSectionState();
}

class _RulesSectionState extends ConsumerState<RulesSection> {
  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(kCommunityRules),
        variables: {'slug': widget.communitySlug},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading)
          return const SizedBox(
              height: 40, child: Center(child: LoadingWidget()));
        final rules = (result.data?['communityRules'] as List?) ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${rules.length} rules',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _addRule(context, refetch),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            if (rules.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('No rules yet. Add rules to guide your community.',
                    style: TextStyle(
                        color: DesignTokens.textSecondary, fontSize: 12)),
              )
            else
              ...rules.asMap().entries.map((entry) {
                final r = entry.value as Map<String, dynamic>;
                final i = entry.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: DesignTokens.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: DesignTokens.primary)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['title']?.toString() ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            if (r['description']?.toString().isNotEmpty == true)
                              Text(r['description'].toString(),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: DesignTokens.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 16, color: DesignTokens.error),
                        onPressed: () => _deleteRule(context, r, refetch),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Future<void> _addRule(BuildContext context, VoidCallback? refetch) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Rule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                  labelText: 'Rule title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add')),
        ],
      ),
    );
    if (result != true || titleCtrl.text.trim().isEmpty) return;
    final client = ref.read(graphqlClientProvider);
    await client.mutate(MutationOptions(
      document: gql(kAddRule),
      variables: {
        'slug': widget.communitySlug,
        'title': titleCtrl.text.trim(),
        'description': descCtrl.text.trim(),
      },
    ));
    refetch?.call();
  }

  Future<void> _deleteRule(BuildContext context, Map<String, dynamic> rule,
      VoidCallback? refetch) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete rule?'),
        content: Text('Delete "${rule['title']}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: DesignTokens.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final client = ref.read(graphqlClientProvider);
    await client.mutate(MutationOptions(
      document: gql(kDeleteRule),
      variables: {'ruleId': rule['id']},
    ));
    refetch?.call();
  }
}
