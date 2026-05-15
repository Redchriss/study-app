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

    return AnimatedPress(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.spMd),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          border: Border.all(
            color: (dark ? DesignTokens.darkBorder : DesignTokens.border).withValues(alpha: 0.5),
          ),
          boxShadow: DesignTokens.shadowSm(dark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _PostTag(
                  label: (post['postType'] ?? 'discussion').toString(),
                  color: _typeColor((post['postType'] ?? '').toString()),
                ),
                if (post['isSolved'] == true)
                  const _PostTag(label: 'Solved', color: DesignTokens.success),
                if (post['isPinned'] == true)
                  const _PostTag(label: 'Pinned', color: DesignTokens.warning),
                Text(
                  post['author']?['username']?.toString() ?? '',
                  style: const TextStyle(fontSize: 12, color: DesignTokens.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              post['title']?.toString() ?? '',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                preview,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(height: 1.45, color: DesignTokens.textSecondary),
              ),
            ],
            if (imageUrl.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                child: Image.network(
                  imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.arrow_upward, size: 14, color: DesignTokens.textTertiary),
                Text('${post['score'] ?? 0}', style: const TextStyle(fontSize: 12, color: DesignTokens.textTertiary)),
                const SizedBox(width: 12),
                const Icon(Icons.chat_bubble_outline, size: 14, color: DesignTokens.textTertiary),
                Text('${post['commentCount'] ?? 0}', style: const TextStyle(fontSize: 12, color: DesignTokens.textTertiary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'question':
        return const Color(0xFF0E7490);
      case 'resource':
        return const Color(0xFF7C3AED);
      default:
        return DesignTokens.primary;
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
