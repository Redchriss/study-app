import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/animated_press.dart';

class CirclePostCard extends StatelessWidget {
  const CirclePostCard({
    super.key,
    required this.post,
    required this.onTap,
  });

  final Map<String, dynamic> post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final preview = (post['body']?.toString() ?? '').trim();
    final imageUrl = post['imageUrl']?.toString() ?? '';
    final String postType = (post['postType'] ?? 'discussion').toString();

    return AnimatedPress(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: dark ? DesignTokens.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _typeColor(postType).withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _typeColor(postType).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _PostTag(
                  label: postType.toUpperCase(),
                  color: _typeColor(postType),
                ),
                if (post['isSolved'] == true) ...[
                  const SizedBox(width: 8),
                  const _PostTag(label: 'SOLVED', color: DesignTokens.success),
                ],
                if (post['isPinned'] == true) ...[
                  const SizedBox(width: 8),
                  const _PostTag(label: 'PINNED', color: DesignTokens.warning),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_rounded, size: 12, color: DesignTokens.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        post['author']?['username']?.toString() ?? '',
                        style: const TextStyle(fontSize: 11, color: DesignTokens.textSecondary, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post['title']?.toString() ?? '',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.3),
            ),
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                preview,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(height: 1.5, color: DesignTokens.textSecondary, fontSize: 14),
              ),
            ],
            if (imageUrl.isNotEmpty) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: (dark ? DesignTokens.darkBorder : DesignTokens.border).withValues(alpha: 0.5))),
              ),
              child: Row(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.keyboard_arrow_up_rounded, size: 18, color: DesignTokens.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${post['score'] ?? 0}', 
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: DesignTokens.primary)
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: DesignTokens.textTertiary),
                      const SizedBox(width: 6),
                      Text(
                        '${post['commentCount'] ?? 0} answers', 
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DesignTokens.textSecondary)
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

  Color _typeColor(String type) {
    switch (type) {
      case 'question':
        return const Color(0xFFE87E5E); // Warm orange
      case 'resource':
        return const Color(0xFF6B48FF); // Purple
      default:
        return const Color(0xFF389E75); // Green for discussion
    }
  }
}

class _PostTag extends StatelessWidget {
  const _PostTag({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
