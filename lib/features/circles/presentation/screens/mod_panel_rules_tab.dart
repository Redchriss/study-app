import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ModPanelRulesTab extends ConsumerStatefulWidget {
  final String communitySlug;
  const ModPanelRulesTab({super.key, required this.communitySlug});

  @override
  ConsumerState<ModPanelRulesTab> createState() => _ModPanelRulesTabState();
}

class _ModPanelRulesTabState extends ConsumerState<ModPanelRulesTab> {
  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(kCommunityRules),
        variables: {'slug': widget.communitySlug},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return const Center(child: LoadingWidget());
        if (result.hasException) {
          return ErrorState(
            message:
                graphQLErrorMessage(result.exception, 'Failed to load rules'),
            onRetry: () => refetch?.call(),
          );
        }
        final rules = (result.data?['communityRules'] as List?) ?? [];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${rules.length} rules',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _addRule(context, refetch),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Rule'),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: rules.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.25),
                        const Center(
                          child: Column(
                            children: [
                              Icon(Icons.rule_outlined,
                                  size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No rules yet',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey)),
                              SizedBox(height: 8),
                              Text('Add rules to guide your community',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : RefreshIndicator(
                      onRefresh: () async => refetch?.call(),
                      child: ReorderableListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: rules.length,
                        itemBuilder: (_, i) {
                          final r = rules[i] as Map<String, dynamic>;
                          return _RuleTile(
                            key: ValueKey(r['id']),
                            rule: r,
                            index: i + 1,
                            communitySlug: widget.communitySlug,
                            onChanged: () => refetch?.call(),
                          );
                        },
                        onReorder: (oldI, newI) async {
                          final client = ref.read(graphqlClientProvider);
                          final rule = rules[oldI] as Map<String, dynamic>;
                          await client.mutate(MutationOptions(
                            document: gql(kUpdateRule),
                            variables: {
                              'ruleId': rule['id'],
                              'order': newI,
                            },
                          ));
                          refetch?.call();
                        },
                      ),
                    ),
            ),
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
}

class _RuleTile extends ConsumerWidget {
  final Map<String, dynamic> rule;
  final int index;
  final String communitySlug;
  final VoidCallback onChanged;

  const _RuleTile({
    super.key,
    required this.rule,
    required this.index,
    required this.communitySlug,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 14,
          backgroundColor: DesignTokens.primary.withValues(alpha: 0.1),
          child: Text('$index',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: DesignTokens.primary)),
        ),
        title: Text(rule['title']?.toString() ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: rule['description']?.toString().isNotEmpty == true
            ? Text(rule['description'].toString(),
                maxLines: 2, overflow: TextOverflow.ellipsis)
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline,
              color: DesignTokens.error, size: 20),
          onPressed: () => _deleteRule(context, ref),
        ),
      ),
    );
  }

  Future<void> _deleteRule(BuildContext context, WidgetRef ref) async {
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
    onChanged();
  }
}
