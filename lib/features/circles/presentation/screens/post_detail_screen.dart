import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/pending_posts_provider.dart';
import 'post_detail_header.dart';
import 'post_detail_comments.dart';
import 'post_detail_actions.dart';
import 'post_detail_action_bar.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String communitySlug;
  final String postSlug;
  final String? commentId;
  const PostDetailScreen({
    super.key,
    required this.communitySlug,
    required this.postSlug,
    this.commentId,
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

    final user = ref.read(authProvider).user;
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final pendings = ref.read(pendingPostsProvider.notifier);
    pendings.add(PendingEntry(
      tempId: tempId,
      type: 'comment',
      groupKey: postId,
      data: {
        'id': tempId,
        'body': body,
        'bodyHtml': body,
        'author': {
          'id': user?['id']?.toString() ?? '',
          'username': user?['username']?.toString() ?? 'me',
        },
        'createdAt': DateTime.now().toIso8601String(),
        'depth': 0,
        'isDeleted': false,
        'isEdited': false,
        'isPinned': false,
        'isAnswer': false,
        'isCollapsed': false,
        'repliesCount': 0,
        'isPending': true,
        'upvoteCount': 0,
        'downvoteCount': 0,
        'score': 0,
        'fuzzedUpvotes': 0,
        'fuzzedDownvotes': 0,
        'fuzzedScore': 0,
      },
    ));

    try {
      final client = ref.read(graphqlClientProvider);
      final result = await client.mutate(MutationOptions(
        document: gql(kAddComment),
        variables: {'postId': postId, 'body': body},
      ));
      if (!mounted) return;
      if (result.hasException) {
        pendings.fail(tempId, 'Could not add comment');
        setState(() => _sending = false);
        return;
      }
      final commentData = result.data?['addComment']?['comment'];
      if (commentData != null) {
        pendings.confirm(tempId, Map<String, dynamic>.from(commentData));
      } else {
        pendings.remove(tempId);
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
                    PostDetailActionBar(
                      postId: postId,
                      isBookmarked: isBookmarked,
                      awarding: _awarding,
                      commentCount:
                          (post['commentCount'] as num?)?.toInt() ?? 0,
                      onToggleSave: () => _toggleSave(postId),
                      onGiveAward: () => _giveAward(postId),
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
                      scrollToCommentId: widget.commentId,
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
