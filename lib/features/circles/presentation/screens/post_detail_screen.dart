import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'post_detail_header.dart';
import 'post_detail_comments.dart';
import 'post_detail_actions.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String communitySlug;
  final String postSlug;
  const PostDetailScreen({
    super.key,
    required this.communitySlug,
    required this.postSlug,
  });

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentCtrl = TextEditingController();
  String _commentSort = 'best';
  bool _sending = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitComment(String postId, VoidCallback? onRefetch) async {
    final body = _commentCtrl.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final client = ref.read(graphqlClientProvider);
      final result = await client.mutate(MutationOptions(
        document: gql(kAddComment),
        variables: {'postId': postId, 'body': body},
      ));
      if (!mounted) return;
      if (result.hasException) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(graphQLErrorMessage(result.exception, 'Could not add comment')),
          backgroundColor: DesignTokens.error,
        ));
        return;
      }
      _commentCtrl.clear();
      onRefetch?.call();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Query(
      options: QueryOptions(
        document: gql(kPost),
        variables: {'communitySlug': widget.communitySlug, 'postSlug': widget.postSlug},
      ),
      builder: (postResult, {fetchMore, refetch}) {
        if (postResult.isLoading) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: LoadingWidget()),
          );
        }
        if (postResult.hasException) {
          return Scaffold(
            appBar: AppBar(),
            body: ErrorState(
              message: graphQLErrorMessage(postResult.exception, 'Could not load post'),
              onRetry: () => refetch?.call(),
            ),
          );
        }

        final post = postResult.data?['post'] as Map<String, dynamic>?;
        if (post == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Post not found')),
          );
        }

        final community = post['community'] as Map<String, dynamic>?;
        final isLocked = post['isLocked'] == true;
        final postId = post['id'].toString();

        return Scaffold(
          appBar: AppBar(
            title: Text('y/${community?['name'] ?? ''}',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {
                  final url = 'https://yaza.app/y/${community?['name'] ?? ''}/post/${post['slug']}';
                  Share.share('${post['title']}\n\n$url', subject: post['title']?.toString());
                },
              ),
              PostActions(postId: postId),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 80),
                  children: [
                    PostDetailHeader(post: post, dark: dark),
                    const SizedBox(height: 8),
                    PostDetailStats(post: post),
                    const Divider(),
                    CommentSortBar(
                      sort: _commentSort,
                      onChanged: (v) => setState(() => _commentSort = v),
                    ),
                    PostCommentsList(
                      key: ValueKey('comments_$postId$_commentSort'),
                      postId: postId,
                      sort: _commentSort,
                    ),
                  ],
                ),
              ),
              if (!isLocked)
                CommentInput(
                  ctrl: _commentCtrl,
                  sending: _sending,
                  onSubmit: () => _submitComment(postId, () => refetch?.call()),
                ),
            ],
          ),
        );
      },
    );
  }
}
