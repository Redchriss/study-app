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
  bool _saved = false;
  bool _awarding = false;

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
          content: Text(
              graphQLErrorMessage(result.exception, 'Could not add comment')),
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

  Future<void> _askAi(String postId, VoidCallback? onRefetch) async {
    final client = ref.read(graphqlClientProvider);
    final result = await client.mutate(MutationOptions(
      document: gql(kAskAiOnPost),
      variables: {'postId': postId},
    ));
    if (!mounted) return;
    if (result.hasException) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            graphQLErrorMessage(result.exception, 'Could not ask AI tutor')),
        backgroundColor: DesignTokens.error,
      ));
      return;
    }
    final comment = result.data?['askAiOnPost']?['comment'];
    if (comment != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('AI Tutor has replied to this post!'),
        backgroundColor: DesignTokens.success,
      ));
      onRefetch?.call();
    } else {
      final errors =
          (result.data?['askAiOnPost']?['errors'] as List?)?.join(', ');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errors ?? 'AI Tutor is not available right now'),
        backgroundColor: DesignTokens.warning,
      ));
    }
  }

  Future<void> _toggleSave(String postId) async {
    final client = ref.read(graphqlClientProvider);
    final doc = _saved ? gql(kUnsavePost) : gql(kSavePost);
    await client
        .mutate(MutationOptions(document: doc, variables: {'postId': postId}));
    if (mounted) setState(() => _saved = !_saved);
  }

  Future<void> _giveAward(String postId) async {
    setState(() => _awarding = true);
    try {
      final client = ref.read(graphqlClientProvider);
      // Use a default award type ID since no picker is implemented
      await client.mutate(MutationOptions(
        document: gql(kGiveAward),
        variables: {'postId': postId, 'awardTypeId': '1'},
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Award given!'),
              backgroundColor: DesignTokens.success),
        );
      }
    } finally {
      if (mounted) setState(() => _awarding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Query(
      options: QueryOptions(
        document: gql(kPost),
        variables: {
          'communitySlug': widget.communitySlug,
          'postSlug': widget.postSlug
        },
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
              message: graphQLErrorMessage(
                  postResult.exception, 'Could not load post'),
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
        final isPinned = post['isPinned'] == true;
        final isRemoved = post['isRemoved'] == true;
        final isMod = community?['isModerator'] == true;
        final postId = post['id'].toString();
        final isBookmarked = post['isBookmarked'] == true || _saved;

        return Scaffold(
          appBar: AppBar(
            title: Text('y/${community?['name'] ?? ''}',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            actions: [
              // Ask AI button
              IconButton(
                icon:
                    const Icon(Icons.auto_awesome, color: DesignTokens.primary),
                tooltip: 'Ask AI Tutor',
                onPressed: () => _askAi(postId, () => refetch?.call()),
              ),
              // Share button
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {
                  final url =
                      'https://yaza.app/y/${community?['name'] ?? ''}/post/${post['slug']}';
                  Share.share('${post['title']}\n\n$url',
                      subject: post['title']?.toString());
                },
              ),
              PostActions(
                postId: postId,
                communitySlug: widget.communitySlug,
                isMod: isMod,
                isPinned: isPinned,
                isLocked: isLocked,
                isRemoved: isRemoved,
                post: post,
                onRefetch: () => refetch?.call(),
              ),
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
                    // Action bar with Award and Save/Saved
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Row(
                        children: [
                          // Award button
                          _awarding
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : TextButton.icon(
                                  onPressed: () => _giveAward(postId),
                                  icon: const Icon(Icons.card_giftcard_outlined,
                                      size: 18, color: DesignTokens.warning),
                                  label: const Text('Award',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: DesignTokens.warning)),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                          const SizedBox(width: 8),
                          // Save/Saved toggle
                          TextButton.icon(
                            onPressed: () => _toggleSave(postId),
                            icon: Icon(
                              isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_outline,
                              size: 18,
                              color: isBookmarked
                                  ? DesignTokens.warning
                                  : DesignTokens.textSecondary,
                            ),
                            label: Text(
                              isBookmarked ? 'Saved' : 'Save',
                              style: TextStyle(
                                fontSize: 12,
                                color: isBookmarked
                                    ? DesignTokens.warning
                                    : DesignTokens.textSecondary,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const Spacer(),
                          // Comment count
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 16, color: DesignTokens.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                              '${(post['commentCount'] as num?)?.toInt() ?? 0}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: DesignTokens.textTertiary)),
                        ],
                      ),
                    ),
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
