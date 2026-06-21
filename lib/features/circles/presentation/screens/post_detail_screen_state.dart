import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/pending_posts_provider.dart';
import 'post_detail_body.dart';
import 'post_detail_screen.dart';

class PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentCtrl = TextEditingController();
  String _commentSort = 'best';
  bool _sending = false;
  bool _saved = false;
  bool _awarding = false;
  int? _userVote;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleVote(String postId, int direction) async {
    final client = ref.read(graphqlClientProvider);
    final result = await client.mutate(MutationOptions(
      document: gql(kVotePost),
      variables: {'postId': postId, 'direction': direction},
    ));
    if (!mounted || result.hasException) return;
    setState(() {
      _userVote = _userVote == direction ? null : direction;
    });
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
        content: Text('Agent has replied to this post!'),
        backgroundColor: DesignTokens.success,
      ));
      onRefetch?.call();
    } else {
      final errors =
          (result.data?['askAiOnPost']?['errors'] as List?)?.join(', ');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errors ?? 'Agent is not available right now'),
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
        final isDeleted = post['isDeleted'] == true;
        final isSpoiler = post['isSpoiler'] == true;
        final isNsfw = post['isNsfw'] == true;
        final isMod = community?['isModerator'] == true;
        final postId = post['id'].toString();
        final isBookmarked = post['isBookmarked'] == true || _saved;
        final currentUserId = ref.read(authProvider).user?['id']?.toString();
        final postAuthorId =
            (post['author'] as Map<String, dynamic>?)?['id']?.toString();
        final isPostAuthor = currentUserId != null &&
            postAuthorId != null &&
            currentUserId == postAuthorId;

        return PostDetailBody(
          dark: dark,
          community: community,
          post: post,
          postId: postId,
          isLocked: isLocked,
          isPinned: isPinned,
          isRemoved: isRemoved,
          isDeleted: isDeleted,
          isSpoiler: isSpoiler,
          isNsfw: isNsfw,
          isMod: isMod,
          isPostAuthor: isPostAuthor,
          isBookmarked: isBookmarked,
          awarding: _awarding,
          userVote: _userVote,
          commentSort: _commentSort,
          commentCtrl: _commentCtrl,
          sending: _sending,
          commentId: widget.commentId,
          onAskAi: () => _askAi(postId, () => refetch?.call()),
          onToggleSave: () => _toggleSave(postId),
          onGiveAward: () => _giveAward(postId),
          onVote: (d) => _toggleVote(postId, d),
          onCommentSortChanged: (v) => setState(() => _commentSort = v),
          onSubmitComment: () => _submitComment(postId, () => refetch?.call()),
          onRefetch: () => refetch?.call(),
        );
      },
    );
  }
}
