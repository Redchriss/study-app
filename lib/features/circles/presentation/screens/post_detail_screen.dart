import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'post_detail_comment_item.dart';
import 'post_detail_post_card.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String circleSlug;
  final String postSlug;
  const PostDetailScreen(
      {super.key, required this.circleSlug, required this.postSlug});
  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentCtrl = TextEditingController();
  bool _sendingComment = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitComment(String postId, VoidCallback? refetch) async {
    final content = _commentCtrl.text.trim();
    if (content.isEmpty || _sendingComment) return;
    setState(() => _sendingComment = true);
    try {
      final result =
          await ref.read(graphqlClientProvider).mutate(MutationOptions(
                document: gql(kAddComment),
                variables: {'postId': postId, 'content': content},
              ));
      if (!mounted) return;
      final payload = result.data?['addComment'];
      if (result.hasException || payload?['success'] != true) {
        final message = result.exception?.graphqlErrors.firstOrNull?.message ??
            (payload?['errors'] as List?)?.firstOrNull?.toString() ??
            'Could not add comment';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: DesignTokens.error),
        );
        return;
      }
      _commentCtrl.clear();
      refetch?.call();
    } finally {
      if (mounted) {
        setState(() => _sendingComment = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Query(
      options: QueryOptions(document: gql(kPostDetail), variables: {
        'circleSlug': widget.circleSlug,
        'postSlug': widget.postSlug
      }),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading)
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        if (result.hasException)
          return Scaffold(
            body: ErrorState(
              message: result.exception?.graphqlErrors.firstOrNull?.message ??
                  'Failed to load post',
              onRetry: () => refetch?.call(),
            ),
          );
        final post = result.data?['circlePost'];
        if (post == null)
          return const Scaffold(body: Center(child: Text('Post not found')));
        return Scaffold(
          appBar: AppBar(title: Text(post['title'] ?? ''), centerTitle: true),
          body: Column(children: [
            Expanded(
                child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.spMd),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PostDetailPostCard(
                      post: post,
                      dark: dark,
                      refetch: refetch,
                    ),
                    const SizedBox(height: 24),
                    SectionHeader(
                        title: 'Comments (${post['commentCount'] ?? 0})'),
                    const SizedBox(height: 16),
                    Query(
                      options: QueryOptions(
                          document: gql(kPostComments),
                          variables: {'postId': post['id']}),
                      builder: (cResult, {fetchMore, refetch}) {
                        if (cResult.isLoading)
                          return const Center(
                              child: CircularProgressIndicator());
                        if (cResult.hasException)
                          return ErrorState(
                            message: cResult.exception?.graphqlErrors
                                    .firstOrNull?.message ??
                                'Failed to load comments',
                            onRetry: () => refetch?.call(),
                          );
                        final comments =
                            (cResult.data?['postComments'] as List?) ?? [];
                        if (comments.isEmpty)
                          return const Text('No comments yet. Be the first!',
                              style:
                                  TextStyle(color: DesignTokens.textSecondary));
                        return Column(
                            children: comments
                                .map((c) => PostDetailCommentItem(
                                      comment: c,
                                      dark: dark,
                                    ))
                                .toList());
                      },
                    ),
                  ]),
            )),
            Container(
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: dark ? DesignTokens.darkSurface : Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4))
                ],
              ),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      filled: true,
                      fillColor: dark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.shade100,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: DesignTokens.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _sendingComment
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: () => _submitComment(post['id'], refetch),
                  ),
                ),
              ]),
            ),
          ]),
        );
      },
    );
  }
}
