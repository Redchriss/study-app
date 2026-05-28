import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class CommunityDrawer extends StatelessWidget {
  const CommunityDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('My Communities',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  // Unread notification indicator
                  Query(
                    options: QueryOptions(
                      document: gql(kNotifications),
                      variables: const {'limit': 1},
                      fetchPolicy: FetchPolicy.networkOnly,
                    ),
                    builder: (result, {refetch, fetchMore}) {
                      final unreadCount =
                          result.data?['unreadNotificationCount'] as num? ?? 0;
                      if (unreadCount > 0) {
                        return Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
            Divider(
                color: dark ? DesignTokens.darkBorder : DesignTokens.border),
            Expanded(
              child: Query(
                options: QueryOptions(document: gql(kMyCommunities)),
                builder: (result, {refetch, fetchMore}) {
                  final communities =
                      (result.data?['myCommunities'] as List?) ?? [];
                  if (result.isLoading) {
                    return const Center(child: LoadingWidget());
                  }
                  if (communities.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No communities yet',
                          style: TextStyle(color: DesignTokens.textSecondary)),
                    );
                  }
                  return ListView.builder(
                    itemCount: communities.length + 1,
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return ListTile(
                          leading: const Icon(Icons.explore_outlined),
                          title: const Text('Discover'),
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/discover');
                          },
                        );
                      }
                      final c = communities[i - 1] as Map<String, dynamic>;
                      final isFav = c['isFavorite'] == true;
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              DesignTokens.primary.withValues(alpha: 0.1),
                          child: c['icon'] != null &&
                                  c['icon'].toString().isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(c['icon'].toString(),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                          Icons.group,
                                          size: 18,
                                          color: DesignTokens.primary)),
                                )
                              : const Icon(Icons.group,
                                  size: 18, color: DesignTokens.primary),
                        ),
                        title: Text('y/${c['name']}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: isFav
                            ? const Icon(Icons.star,
                                size: 16, color: DesignTokens.warning)
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/y/${c['slug']}');
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Create Community'),
              onTap: () {
                Navigator.pop(context);
                context.push('/create-community');
              },
            ),
          ],
        ),
      ),
    );
  }
}
