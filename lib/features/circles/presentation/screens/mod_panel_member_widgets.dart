import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class ModList extends StatelessWidget {
  final String communitySlug;
  const ModList({super.key, required this.communitySlug});

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
          document: gql(kCommunityModerators),
          variables: {'slug': communitySlug}),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return const Center(child: LoadingWidget());
        final mods = (result.data?['communityModerators'] as List?) ?? [];
        if (mods.isEmpty) {
          return const Center(
              child: Text('No moderators',
                  style: TextStyle(color: DesignTokens.textSecondary)));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('${mods.length} moderators',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
            ...mods.map((m) {
              final user =
                  (m as Map<String, dynamic>)['user'] as Map<String, dynamic>?;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: DesignTokens.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.shield_rounded,
                      size: 18, color: DesignTokens.primary),
                ),
                title: Text('u/${user?['username'] ?? 'unknown'}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(m['role']?.toString() ?? ''),
              );
            }),
          ],
        );
      },
    );
  }
}
