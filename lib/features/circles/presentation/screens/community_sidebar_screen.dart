import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class CommunitySidebarScreen extends ConsumerWidget {
  final String slug;
  const CommunitySidebarScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Query(
      options: QueryOptions(
        document: gql(r'''
          query CommunitySidebar($slug: String!) {
            community(slug: $slug) {
              id slug name displayName description sidebarMarkdown memberCount postCount
              createdAt communityType
            }
            communityModerators(slug: $slug) { id role user { username } }
            communityRules(slug: $slug) { id title description order }
          }
        '''),
        variables: {'slug': slug},
      ),
      builder: (QueryResult result,
          {VoidCallback? refetch, FetchMore? fetchMore}) {
        if (result.isLoading)
          return Scaffold(
              appBar: AppBar(), body: const Center(child: LoadingWidget()));
        final c = result.data?['community'] as Map<String, dynamic>?;
        if (c == null)
          return Scaffold(
              appBar: AppBar(), body: const Center(child: Text('Not found')));
        final rules = (result.data?['communityRules'] as List?) ?? [];
        final mods = (result.data?['communityModerators'] as List?) ?? [];
        return Scaffold(
          appBar: AppBar(title: Text('y/${c['name']} info')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(c['displayName']?.toString() ?? '',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('y/${c['name']}',
                  style: const TextStyle(color: DesignTokens.textSecondary)),
              const SizedBox(height: 12),
              if (c['description'] != null &&
                  c['description'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(c['description'].toString(),
                      style: const TextStyle(height: 1.4)),
                ),
              Row(children: [
                _stat(Icons.people_outline, '${c['memberCount'] ?? 0} members'),
                const SizedBox(width: 16),
                _stat(Icons.article_outlined, '${c['postCount'] ?? 0} posts'),
                const SizedBox(width: 16),
                _stat(Icons.lock_outline,
                    c['communityType']?.toString() ?? 'public'),
              ]),
              const Divider(height: 32),
              Text('Rules',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (rules.isEmpty)
                const Text('No rules yet',
                    style: TextStyle(color: DesignTokens.textSecondary))
              else
                ...rules.asMap().entries.map((e) {
                  final r = e.value as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${e.key + 1}. ${r['title'] ?? ''}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          if (r['description'] != null &&
                              r['description'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(r['description'].toString(),
                                  style: const TextStyle(
                                      color: DesignTokens.textSecondary,
                                      fontSize: 13)),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              const Divider(height: 32),
              Text('Moderators',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ...mods.map((m) {
                final user = (m as Map<String, dynamic>)['user']
                    as Map<String, dynamic>?;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    const Icon(Icons.shield_rounded,
                        size: 16, color: DesignTokens.primary),
                    const SizedBox(width: 8),
                    Text('u/${user?['username'] ?? 'unknown'}'),
                  ]),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _stat(IconData icon, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: DesignTokens.textSecondary),
      const SizedBox(width: 4),
      Text(label,
          style:
              const TextStyle(color: DesignTokens.textSecondary, fontSize: 13)),
    ]);
  }
}
