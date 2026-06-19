import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/design_tokens.dart';
import 'post_detail_header.dart';
import 'post_detail_comments.dart';
import 'post_detail_actions.dart';
import 'post_detail_action_bar.dart';
import 'post_actions_menu.dart';

class PostDetailBody extends StatelessWidget {
  final bool dark;
  final Map<String, dynamic>? community;
  final Map<String, dynamic> post;
  final String postId;
  final bool isLocked, isPinned, isRemoved, isDeleted, isSpoiler, isNsfw, isMod;
  final bool isPostAuthor;
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

  const PostDetailBody({
    super.key,
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
    this.isPostAuthor = false,
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
            icon: const Icon(Icons.psychology_rounded, color: DesignTokens.primary),
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
                  canModerate: isMod,
                  canMarkAnswer: isPostAuthor,
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
