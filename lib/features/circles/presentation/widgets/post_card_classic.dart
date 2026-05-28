import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

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
    final isRemoved = post['isRemoved'] == true;
    final isDeleted = post['isDeleted'] == true;
    final isLocked = post['isLocked'] == true;
    final isPinned = post['isPinned'] == true;
    final isSpoiler = post['isSpoiler'] == true;
    final isNsfw = post['isNsfw'] == true;

    final hasStateBadge = isRemoved || isDeleted || isLocked || isNsfw;
    final hasBlurredThumb =
        (isSpoiler && !_spoilerRevealed) || (isNsfw && !_nsfwRevealed);

    return AnimatedPress(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? DesignTokens.darkSurface
              : DesignTokens.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(color: DesignTokens.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 64,
                height: 64,
                child: _buildThumbnail(hasBlurredThumb, isSpoiler, isNsfw),
              ),
            ),
            const SizedBox(width: 12),
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
                              ? _stateBadgeText(isRemoved, isDeleted, isLocked)
                              : (post['title']?.toString() ?? ''),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: hasStateBadge ? Colors.grey : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isLocked
                            ? Icons.lock_rounded
                            : Icons.arrow_upward_rounded,
                        size: 12,
                        color: isLocked
                            ? DesignTokens.warning
                            : DesignTokens.textTertiary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${_count((post['fuzzedScore'] as num?)?.toInt() ?? 0)} pts • ${_count(post['commentCount'])} comments',
                        style: const TextStyle(
                            fontSize: 11, color: DesignTokens.textTertiary),
                      ),
                    ],
                  ),
                ],
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

    if (!hasImage) return _placeholderIcon();

    if (blurred) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Image.network(
              post['imageUrl'].toString(),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholderIcon(),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                if (isSpoiler) _spoilerRevealed = true;
                if (isNsfw) _nsfwRevealed = true;
              });
            },
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

    return Image.network(
      post['imageUrl'].toString(),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholderIcon(),
    );
  }

  Widget _placeholderIcon() => Container(
        color: DesignTokens.surfaceVariant,
        child: const Icon(Icons.article_outlined,
            color: DesignTokens.textTertiary, size: 28),
      );

  String _stateBadgeText(bool removed, bool deleted, bool locked) {
    if (removed) return '[Removed]';
    if (deleted) return '[Deleted]';
    if (locked) return '🔒 Locked';
    return '';
  }

  String _count(dynamic val) {
    final n = (val as num?)?.toInt() ?? 0;
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}
