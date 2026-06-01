import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

const String kUserComments = r'''query UserComments { __typename }''';

class ProfileCommentsTab extends StatelessWidget {
  final String username;
  const ProfileCommentsTab({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(kUserComments),
        variables: {'username': username, 'sort': 'new', 'limit': 25},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Column(children: [
              ShimmerBox(height: 60, radius: 8),
              SizedBox(height: 8),
              ShimmerBox(height: 60, radius: 8),
            ]),
          );
        }

        final data = result.data?['userComments'];
        final edges = (data?['edges'] as List?) ?? [];
        final comments =
            edges.map((e) => e['node'] as Map<String, dynamic>).toList();

        if (comments.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_outlined, size: 48, color: DesignTokens.textTertiary),
                  SizedBox(height: 12),
                  Text('No comments yet',
                      style: TextStyle(color: DesignTokens.textSecondary, fontSize: 15)),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => refetch?.call(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            itemCount: comments.length,
            itemBuilder: (_, i) {
              final c = comments[i];
              final score = (c['fuzzedScore'] as num?)?.toInt() ?? 0;
              final body = c['body']?.toString() ?? '';
              final createdAt = c['createdAt']?.toString() ?? '';
              final post = c['post'] as Map<String, dynamic>?;
              final postTitle = post?['title']?.toString() ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: DesignTokens.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.arrow_upward,
                            size: 12, color: DesignTokens.textTertiary),
                        const SizedBox(width: 2),
                        Text('$score',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: DesignTokens.textSecondary)),
                        const SizedBox(width: 8),
                        if (postTitle.isNotEmpty)
                          Expanded(
                            child: Text(postTitle,
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11, color: DesignTokens.primary)),
                          ),
                        Text(_timeAgo(createdAt),
                            style: const TextStyle(
                                fontSize: 11, color: DesignTokens.textTertiary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(body,
                        maxLines: 3, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, height: 1.4)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${diff.inDays}d';
    } catch (_) {
      return '';
    }
  }
}
