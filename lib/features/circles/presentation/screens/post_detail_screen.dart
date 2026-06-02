import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import 'post_actions_menu.dart';

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
        final isDeleted = post['isDeleted'] == true;
        final isSpoiler = post['isSpoiler'] == true;
        final isNsfw = post['isNsfw'] == true;
        final isMod = community?['isModerator'] == true;
        final postId = post['id'].toString();
        final isBookmarked = post['isBookmarked'] == true || _saved;

        return _PostDetailBody(
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

class _PostDetailBody extends StatelessWidget {
  final bool dark;
  final Map<String, dynamic>? community;
  final Map<String, dynamic> post;
  final String postId;
  final bool isLocked, isPinned, isRemoved, isDeleted, isSpoiler, isNsfw, isMod;
  final bool isBookmarked, awarding;
  final int? userVote;
  final String commentSort;
  final TextEditingController commentCtrl;
  final bool sending;
  final String? commentId;
  final VoidCallback onAskAi, onToggleSave, onGiveAward, onRefetch;
  final void Function(int) onVote;
  final void Function(String) onCommentSortChanged;
  final VoidCallback onSubmitComment;

  const _PostDetailBody({
    required this.dark,
    required this.community,
    required this.post,
    required this.postId,
    required this.isLocked,
    required this.isPinned,
    required this.isRemoved,
    required this.isDeleted,
    required this.isSpoiler,
    required this.isNsfw,
    required this.isMod,
    required this.isBookmarked,
    required this.awarding,
    required this.userVote,
    required this.commentSort,
    required this.commentCtrl,
    required this.sending,
    required this.commentId,
    required this.onAskAi,
    required this.onToggleSave,
    required this.onGiveAward,
    required this.onVote,
    required this.onCommentSortChanged,
    required this.onSubmitComment,
    required this.onRefetch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerWidgets = <Widget>[
      if (isRemoved)
        _buildRemovedBanner()
      else ...[
        PostDetailHeader(post: post, dark: dark),
        const SizedBox(height: 8),
        PostDetailActionBar(
          postId: postId,
          isBookmarked: isBookmarked,
          awarding: awarding,
          userVote: userVote,
          score: (post['fuzzedScore'] as num?)?.toInt() ?? 0,
          commentCount: (post['commentCount'] as num?)?.toInt() ?? 0,
          onToggleSave: onToggleSave,
          onGiveAward: onGiveAward,
          onVote: onVote,
        ),
      ],
      const Divider(),
      if (!isLocked && !isDeleted)
        CommentSortBar(
          sort: commentSort,
          onChanged: onCommentSortChanged,
        ),
      if (isLocked)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.lock_rounded,
                  size: 16, color: DesignTokens.textTertiary),
              SizedBox(width: 8),
              Text('Post is locked — no new comments',
                  style: TextStyle(
                      fontSize: 13, color: DesignTokens.textSecondary)),
            ],
          ),
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => context
              .push('/y/${community?['slug'] ?? community?['name'] ?? ''}'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: DesignTokens.primary.withValues(alpha: 0.15),
                backgroundImage:
                    (community?['icon']?.toString() ?? '').isNotEmpty
                        ? NetworkImage(community!['icon'].toString())
                        : null,
                child: (community?['icon']?.toString() ?? '').isEmpty
                    ? Text(
                        (community?['name']?.toString() ?? '?')[0]
                            .toUpperCase(),
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: DesignTokens.primary),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'y/${community?['name'] ?? ''}',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: DesignTokens.primary),
            tooltip: 'Ask AI Tutor',
            onPressed: onAskAi,
          ),
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
            communitySlug: community?['slug']?.toString() ?? '',
            isMod: isMod,
            isPinned: isPinned,
            isLocked: isLocked,
            isRemoved: isRemoved,
            post: post,
            onRefetch: onRefetch,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: headerWidgets.length + 1,
              itemBuilder: (context, index) {
                if (index < headerWidgets.length) return headerWidgets[index];
                return PostCommentsList(
                  key: ValueKey('comments_$postId$commentSort'),
                  postId: postId,
                  sort: commentSort,
                  scrollToCommentId: commentId,
                );
              },
            ),
          ),
          if (!isLocked && !isDeleted)
            CommentInput(
              ctrl: commentCtrl,
              sending: sending,
              onSubmit: onSubmitComment,
            ),
        ],
      ),
    );
  }

  Widget _buildRemovedBanner() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.visibility_off_rounded,
              size: 48, color: DesignTokens.textTertiary),
          const SizedBox(height: 12),
          Text('[removed]',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.textSecondary)),
          const SizedBox(height: 4),
          Text('This post has been removed by moderators',
              style: TextStyle(fontSize: 13, color: DesignTokens.textTertiary)),
        ],
      ),
    );
  }
}
