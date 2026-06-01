import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/pending_posts_provider.dart';
import 'comment_item.dart';

class PostCommentsList extends StatefulWidget {
  final String postId;
  final String sort;
  final String? scrollToCommentId;
  const PostCommentsList({
    super.key,
    required this.postId,
    required this.sort,
    this.scrollToCommentId,
  });

  @override
  State<PostCommentsList> createState() => _PostCommentsListState();
}

class _PostCommentsListState extends State<PostCommentsList> {
  bool _hasScrolled = false;

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(kPostComments),
        variables: {'postId': widget.postId, 'sort': widget.sort, 'limit': 25},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (QueryResult result,
          {VoidCallback? refetch, FetchMore? fetchMore}) {
        if (result.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Column(children: [
              ShimmerBox(height: 60, radius: 8),
              SizedBox(height: 8),
              ShimmerBox(height: 60, radius: 8),
            ]),
          );
        }

        final data = result.data?['postComments'];
        final edges = (data?['edges'] as List?) ?? [];
        final comments =
            edges.map((e) => e['node'] as Map<String, dynamic>).toList();
        final hasNextPage = data?['pageInfo']?['hasNextPage'] == true;
        final endCursor = data?['pageInfo']?['endCursor']?.toString();

        return Consumer(builder: (context, ref, _) {
          final pendingComments = ref
              .watch(pendingPostsProvider)
              .where((e) => e.groupKey == widget.postId && e.type == 'comment')
              .toList();

          if (comments.isEmpty && pendingComments.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No comments yet',
                    style: TextStyle(color: DesignTokens.textSecondary)),
              ),
            );
          }

          final commentKeys = <String, GlobalKey>{};
          for (final c in comments) {
            commentKeys[c['id'].toString()] = GlobalKey();
          }

          if (widget.scrollToCommentId != null &&
              !_hasScrolled &&
              comments.isNotEmpty) {
            final targetKey = commentKeys[widget.scrollToCommentId];
            if (targetKey?.currentContext != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || _hasScrolled) return;
                _hasScrolled = true;
                Scrollable.ensureVisible(
                  targetKey!.currentContext!,
                  alignment: 0.3,
                  duration: const Duration(milliseconds: 300),
                );
              });
            }
          }

          return Column(
            children: [
              ...pendingComments.map((e) => CommentItem(
                    key: ValueKey('pending_${e.tempId}'),
                    comment: e.data,
                    postId: widget.postId,
                    onRefetch: refetch,
                    isPending: e.status == PendingStatus.submitting,
                    onRetry: e.status == PendingStatus.failed
                        ? () {
                            ref
                                .read(pendingPostsProvider.notifier)
                                .remove(e.tempId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please try posting again')),
                            );
                          }
                        : null,
                  )),
              ...comments.map((c) => CommentItem(
                    key: commentKeys[c['id'].toString()],
                    comment: c,
                    postId: widget.postId,
                    onRefetch: refetch,
                  )),
              if (hasNextPage)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextButton(
                    onPressed: () {
                      fetchMore?.call(FetchMoreOptions(
                        variables: {'after': endCursor},
                        updateQuery: (prev, next) {
                          if (next?['postComments'] == null) return prev;
                          final merged = Map<String, dynamic>.from(prev ?? {});
                          final prevData = Map<String, dynamic>.from(
                              prev?['postComments'] ?? {});
                          final nextData =
                              Map<String, dynamic>.from(next!['postComments']);
                          final prevEdges = (prevData['edges'] as List?) ?? [];
                          final nextEdges = (nextData['edges'] as List?) ?? [];
                          merged['postComments'] = {
                            ...nextData,
                            'edges': [...prevEdges, ...nextEdges],
                          };
                          return merged;
                        },
                      ));
                    },
                    child: const Text('Load more comments'),
                  ),
                ),
            ],
          );
        });
      },
    );
  }
}
