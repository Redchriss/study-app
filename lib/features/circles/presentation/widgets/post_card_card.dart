import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import 'vote_buttons.dart';

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isRemoved && !_removedRevealed)
              _buildRemovedOverlay()
            else ...[
              if (community != null) ...[
                if (community['icon'] != null &&
                    community['icon'].toString().isNotEmpty)
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      community['icon'].toString(),
                      height: 80,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      Text('y/${community['name']}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.primary,
                          )),
                      const SizedBox(width: 4),
                      Text('• Posted by u/${author?['username'] ?? 'unknown'}',
                          style: const TextStyle(
                              fontSize: 11, color: DesignTokens.textTertiary)),
                      const Spacer(),
                      if (isPinned)
                        const Icon(Icons.push_pin_rounded,
                            size: 14, color: DesignTokens.warning),
                    ],
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (post['flairText'] != null &&
                        post['flairText'].toString().isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(right: 6, top: 2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: DesignTokens.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(post['flairText'].toString(),
                            style: const TextStyle(
                                fontSize: 10, color: DesignTokens.primary)),
                      ),
                    Expanded(
                      child: Text(
                        post['title']?.toString() ?? '',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDeleted)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('[deleted]',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic)),
                  ),
                )
              else if (post['body'] != null &&
                  post['body'].toString().trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                  child: Text(
                    post['body'].toString(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, color: DesignTokens.textSecondary),
                  ),
                ),
              if (post['imageUrl'] != null &&
                  post['imageUrl'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildMedia(
                      imageUrl: post['imageUrl'].toString(),
                      isSpoiler: isSpoiler && !_spoilerRevealed,
                      isNsfw: isNsfw && !_nsfwRevealed,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 8, 8),
                child: Row(
                  children: [
                    VoteButtons(
                      postId: post['id'].toString(),
                      upvotes: (post['fuzzedUpvotes'] as num?)?.toInt() ?? 0,
                      downvotes:
                          (post['fuzzedDownvotes'] as num?)?.toInt() ?? 0,
                      score: (post['fuzzedScore'] as num?)?.toInt() ?? 0,
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      isLocked
                          ? Icons.lock_rounded
                          : Icons.chat_bubble_outline_rounded,
                      size: 16,
                      color: isLocked
                          ? DesignTokens.warning
                          : DesignTokens.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(_count(post['commentCount']),
                        style: TextStyle(
                            fontSize: 12,
                            color: isLocked
                                ? DesignTokens.warning
                                : DesignTokens.textTertiary)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        final comm = post['community'] as Map<String, dynamic>?;
                        final url =
                            'https://yaza.app/y/${comm?['name'] ?? ''}/post/${post['slug']}';
                        Share.share('${post['title']}\n\n$url',
                            subject: post['title']?.toString());
                      },
                      child: const Icon(Icons.share_outlined,
                          size: 16, color: DesignTokens.textTertiary),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.bookmark_outline_rounded,
                        size: 16, color: DesignTokens.textTertiary),
                  ],
                ),
              ),
              if (isSpoiler && !_spoilerRevealed)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                  decoration: BoxDecoration(
                    color: DesignTokens.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('SPOILER',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: DesignTokens.warning)),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRemovedOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _removedRevealed = true),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          color: Colors.grey.withValues(alpha: 0.08),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.visibility_off_rounded,
                  size: 32, color: Colors.grey),
              const SizedBox(height: 8),
              const Text('[removed]',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey)),
              const SizedBox(height: 4),
              Text('Tap to view original',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedia({
    required String imageUrl,
    required bool isSpoiler,
    required bool isNsfw,
  }) {
    Widget image = Image.network(
      imageUrl,
      height: 160,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : const ShimmerBox(height: 160, radius: 8),
    );

    if (isSpoiler || isNsfw) {
      final label = isNsfw ? 'NSFW — Tap to view' : 'Spoiler — Tap to view';
      image = Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Image.network(
                  imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (isSpoiler) _spoilerRevealed = true;
                  if (isNsfw) _nsfwRevealed = true;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isNsfw
                          ? Icons.warning_amber_rounded
                          : Icons.visibility_off_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      height: 160,
      width: double.infinity,
      child: image,
    );
  }

  String _count(dynamic val) {
    final n = (val as num?)?.toInt() ?? 0;
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}
