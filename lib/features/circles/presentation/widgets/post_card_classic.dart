import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import 'post_card_classic_vote_column.dart';
import 'post_card_classic_community_avatar.dart';

class ClassicPostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback onTap;
  const ClassicPostCard({super.key, required this.post, required this.onTap});

  @override
  State<ClassicPostCard> createState() => _ClassicPostCardState();
}

class _ClassicPostCardState extends State<ClassicPostCard> {
  bool _spoilerRevealed = false;
  bool _nsfwRevealed = false;

  Map<String, dynamic> get post => widget.post;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
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
    final hasBlur =
        (isSpoiler && !_spoilerRevealed) || (isNsfw && !_nsfwRevealed);

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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left vote column
            ClassicVoteColumn(
              postId: post['id'].toString(),
              score: _toInt(post['fuzzedScore']),
              userVote: _toNullableInt(post['voteDirection']),
              dark: dark,
            ),
            // Thumbnail
            Padding(
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: _buildThumbnail(hasBlur, isSpoiler, isNsfw),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Community + author
                    Row(
                      children: [
                        ClassicCommunityAvatar(community: community),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'y/${community?['name'] ?? '?'} · u/${author?['username'] ?? '?'}',
                            style: const TextStyle(
                                fontSize: 10, color: DesignTokens.textTertiary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPinned)
                          const Icon(Icons.push_pin_rounded,
                              size: 12, color: DesignTokens.warning),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Title
                    Text(
                      hasStateBadge
                          ? _stateBadge(isRemoved, isDeleted, isLocked)
                          : (post['title']?.toString() ?? ''),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: hasStateBadge ? Colors.grey : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Comments count
                    Row(
                      children: [
                        Icon(
                          isLocked
                              ? Icons.lock_rounded
                              : Icons.chat_bubble_outline_rounded,
                          size: 12,
                          color: isLocked
                              ? DesignTokens.warning
                              : DesignTokens.textTertiary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _count(post['commentCount']),
                          style: TextStyle(
                              fontSize: 11,
                              color: isLocked
                                  ? DesignTokens.warning
                                  : DesignTokens.textTertiary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(bool blurred, bool isSpoiler, bool isNsfw) {
    final hasImage =
        post['imageUrl'] != null && post['imageUrl'].toString().isNotEmpty;

    if (!hasImage) {
      return Container(
        color: DesignTokens.surfaceVariant,
        child: const Icon(Icons.article_outlined,
            color: DesignTokens.textTertiary, size: 28),
      );
    }

    if (blurred) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Image.network(post['imageUrl'].toString(),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          ),
          GestureDetector(
            onTap: () => setState(() {
              if (isSpoiler) _spoilerRevealed = true;
              if (isNsfw) _nsfwRevealed = true;
            }),
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: Center(
                child: Icon(
                  isNsfw
                      ? Icons.warning_amber_rounded
                      : Icons.visibility_off_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Image.network(post['imageUrl'].toString(),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
              color: DesignTokens.surfaceVariant,
              child: const Icon(Icons.broken_image_outlined,
                  color: DesignTokens.textTertiary, size: 24),
            ));
  }

  String _stateBadge(bool removed, bool deleted, bool locked) {
    if (removed) return '[Removed]';
    if (deleted) return '[Deleted]';
    if (locked) return '🔒 Locked';
    return '';
  }

  String _count(dynamic val) {
    final n = _toInt(val);
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  int _toInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

  int? _toNullableInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
}
