import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import 'post_card_states.dart';

class CardPostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback onTap;
  const CardPostCard({super.key, required this.post, required this.onTap});

  @override
  State<CardPostCard> createState() => _CardPostCardState();
}

class _CardPostCardState extends State<CardPostCard> {
  bool _spoilerRevealed = false;
  bool _nsfwRevealed = false;
  bool _removedRevealed = false;

  Map<String, dynamic> get post => widget.post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final community = post['community'] as Map<String, dynamic>?;
    final author = post['author'] as Map<String, dynamic>?;
    final isPinned = post['isPinned'] == true;
    final isRemoved = post['isRemoved'] == true;
    final isDeleted = post['isDeleted'] == true;
    final isLocked = post['isLocked'] == true;
    final isSpoiler = post['isSpoiler'] == true;
    final isNsfw = post['isNsfw'] == true;

    return AnimatedPress(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(
              color: dark ? DesignTokens.darkBorder : DesignTokens.border),
        ),
        child: isRemoved && !_removedRevealed
            ? RemovedOverlay(
                onReveal: () => setState(() => _removedRevealed = true))
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Left: Reddit-style vote column ─────────────────────
                  _VoteColumn(
                    postId: post['id'].toString(),
                    score: (post['fuzzedScore'] as num?)?.toInt() ?? 0,
                    userVote: (post['voteDirection'] as num?)?.toInt(),
                    dark: dark,
                  ),
                  // ── Right: content ────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 10, 10, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Community avatar + name + author
                          Row(
                            children: [
                              _CommunityAvatar(community: community),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(children: [
                                    TextSpan(
                                      text: 'y/${community?['name'] ?? '?'}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: DesignTokens.primary),
                                    ),
                                    TextSpan(
                                      text:
                                          '  ·  u/${author?['username'] ?? '?'}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: DesignTokens.textTertiary),
                                    ),
                                  ]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isPinned)
                                const Icon(Icons.push_pin_rounded,
                                    size: 13, color: DesignTokens.warning),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Flair
                          if (post['flairText'] != null &&
                              post['flairText'].toString().isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color:
                                    DesignTokens.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(post['flairText'].toString(),
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: DesignTokens.primary)),
                            ),
                          // Title
                          Text(
                            post['title']?.toString() ?? '',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Body preview
                          if (isDeleted) ...[
                            const SizedBox(height: 3),
                            const DeletedBody(),
                          ] else if (post['body'] != null &&
                              post['body'].toString().trim().isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              post['body'].toString(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: DesignTokens.textSecondary),
                            ),
                          ],
                          // Image
                          if (post['imageUrl'] != null &&
                              post['imageUrl'].toString().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: (isSpoiler && !_spoilerRevealed) ||
                                      (isNsfw && !_nsfwRevealed)
                                  ? SpoilerNsfwMedia(
                                      imageUrl: post['imageUrl'].toString(),
                                      isSpoiler: isSpoiler && !_spoilerRevealed,
                                      isNsfw: isNsfw && !_nsfwRevealed,
                                      onReveal: () => setState(() {
                                        if (isSpoiler) _spoilerRevealed = true;
                                        if (isNsfw) _nsfwRevealed = true;
                                      }),
                                    )
                                  : PlainMedia(
                                      imageUrl: post['imageUrl'].toString()),
                            ),
                          ],
                          // Bottom action bar
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                isLocked
                                    ? Icons.lock_rounded
                                    : Icons.chat_bubble_outline_rounded,
                                size: 14,
                                color: isLocked
                                    ? DesignTokens.warning
                                    : DesignTokens.textTertiary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                formatCount(post['commentCount']),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isLocked
                                        ? DesignTokens.warning
                                        : DesignTokens.textTertiary),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  final url =
                                      'https://yaza.app/y/${community?['name'] ?? ''}/post/${post['slug']}';
                                  Share.share('${post['title']}\n\n$url',
                                      subject: post['title']?.toString());
                                },
                                child: const Icon(Icons.share_outlined,
                                    size: 15, color: DesignTokens.textTertiary),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.bookmark_outline_rounded,
                                  size: 15, color: DesignTokens.textTertiary),
                            ],
                          ),
                          if (isSpoiler && !_spoilerRevealed)
                            const SpoilerBadge(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Reddit-style vertical vote column on left edge ───────────────────────────
class _VoteColumn extends ConsumerWidget {
  final String postId;
  final int score;
  final int? userVote;
  final bool dark;

  const _VoteColumn({
    required this.postId,
    required this.score,
    required this.dark,
    this.userVote,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Mutation(
      options: MutationOptions(document: gql(kVotePost)),
      builder: (runMutation, result) {
        void vote(int dir) {
          if (result?.isLoading ?? false) return;
          runMutation({'postId': postId, 'direction': dir});
        }

        final upColor =
            userVote == 1 ? DesignTokens.secondary : DesignTokens.textTertiary;
        final downColor =
            userVote == -1 ? DesignTokens.error : DesignTokens.textTertiary;
        final scoreColor = userVote == 1
            ? DesignTokens.secondary
            : userVote == -1
                ? DesignTokens.error
                : DesignTokens.textSecondary;

        return Container(
          width: 40,
          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(DesignTokens.radiusMd),
              bottomLeft: Radius.circular(DesignTokens.radiusMd),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => vote(1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Icon(Icons.arrow_upward_rounded,
                      size: 20, color: upColor),
                ),
              ),
              Text(
                _fmt(score),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: scoreColor),
              ),
              GestureDetector(
                onTap: () => vote(-1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Icon(Icons.arrow_downward_rounded,
                      size: 20, color: downColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

// ── Community circle avatar — always shown, letter fallback ─────────────────
class _CommunityAvatar extends StatelessWidget {
  final Map<String, dynamic>? community;
  const _CommunityAvatar({this.community});

  @override
  Widget build(BuildContext context) {
    final icon = community?['icon']?.toString() ?? '';
    final name = community?['name']?.toString() ?? '?';
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 10,
      backgroundColor: DesignTokens.primary.withValues(alpha: 0.15),
      backgroundImage: icon.isNotEmpty ? NetworkImage(icon) : null,
      onBackgroundImageError: icon.isNotEmpty ? (_, __) {} : null,
      child: icon.isEmpty
          ? Text(letter,
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: DesignTokens.primary))
          : null,
    );
  }
}
