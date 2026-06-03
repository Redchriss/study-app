import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import 'post_card_states.dart';
import 'post_card_card_vote_column.dart';
import 'post_card_card_community_avatar.dart';

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
                  CardVoteColumn(
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
                              CardCommunityAvatar(community: community),
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
