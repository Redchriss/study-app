import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import 'vote_buttons.dart';

class CompactPostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onTap;
  const CompactPostCard({super.key, required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rawCommunity = post['community'];
    final community =
        rawCommunity is Map ? Map<String, dynamic>.from(rawCommunity) : null;
    final rawAuthor = post['author'];
    final author =
        rawAuthor is Map ? Map<String, dynamic>.from(rawAuthor) : null;
    final isRemoved = post['isRemoved'] == true;
    final isDeleted = post['isDeleted'] == true;
    final isLocked = post['isLocked'] == true;
    final isPinned = post['isPinned'] == true;
    final isSpoiler = post['isSpoiler'] == true;
    final isNsfw = post['isNsfw'] == true;

    final hasStateBadge = isRemoved || isDeleted || isLocked || isNsfw;

    return AnimatedPress(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: DesignTokens.border.withValues(alpha: 0.5))),
        ),
        child: Row(
          children: [
            VoteButtons(
              postId: post['id'].toString(),
              upvotes: (post['fuzzedUpvotes'] as num?)?.toInt() ?? 0,
              downvotes: (post['fuzzedDownvotes'] as num?)?.toInt() ?? 0,
              score: (post['fuzzedScore'] as num?)?.toInt() ?? 0,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isPinned) ...[
                        const Icon(Icons.push_pin_rounded,
                            size: 14, color: DesignTokens.warning),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          hasStateBadge
                              ? _stateBadgeText(
                                  isRemoved, isDeleted, isLocked, isNsfw)
                              : (post['title']?.toString() ?? ''),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: hasStateBadge ? Colors.grey : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSpoiler)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: DesignTokens.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text('SPOILER',
                              style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: DesignTokens.warning)),
                        ),
                    ],
                  ),
                  if (hasStateBadge) ...[
                    const SizedBox(height: 2),
                    Text(
                      post['title']?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: DesignTokens.textTertiary),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _CompactCommunityAvatar(community: community),
                      const SizedBox(width: 4),
                      Text(
                        'y/${community?['name'] ?? '?'} • u/${author?['username'] ?? '?'}',
                        style: const TextStyle(
                            fontSize: 11, color: DesignTokens.textTertiary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isLocked ? Icons.lock_rounded : Icons.chat_bubble_outline_rounded,
              size: 14,
              color:
                  isLocked ? DesignTokens.warning : DesignTokens.textTertiary,
            ),
            const SizedBox(width: 2),
            Text(_count(post['commentCount']),
                style: TextStyle(
                    fontSize: 12,
                    color: isLocked
                        ? DesignTokens.warning
                        : DesignTokens.textTertiary)),
          ],
        ),
      ),
    );
  }

  String _stateBadgeText(bool removed, bool deleted, bool locked, bool nsfw) {
    if (removed) return '[Removed]';
    if (deleted) return '[Deleted]';
    if (locked) return '🔒 Locked';
    if (nsfw) return 'NSFW';
    return '';
  }

  String _count(dynamic val) {
    final n =
        val is num ? val.toInt() : int.tryParse(val?.toString() ?? '') ?? 0;
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

class _CompactCommunityAvatar extends StatelessWidget {
  final Map<String, dynamic>? community;
  const _CompactCommunityAvatar({this.community});

  @override
  Widget build(BuildContext context) {
    final icon = community?['icon']?.toString() ?? '';
    final name = community?['name']?.toString() ?? '?';
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 8,
      backgroundColor: DesignTokens.primary.withValues(alpha: 0.15),
      backgroundImage: icon.isNotEmpty ? NetworkImage(icon) : null,
      onBackgroundImageError: icon.isNotEmpty ? (_, __) {} : null,
      child: icon.isEmpty
          ? Text(letter,
              style: const TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  color: DesignTokens.primary))
          : null,
    );
  }
}
