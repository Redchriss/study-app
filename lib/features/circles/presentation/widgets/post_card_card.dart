import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import 'vote_buttons.dart';

class CardPostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onTap;
  const CardPostCard({super.key, required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final community = post['community'] as Map<String, dynamic>?;
    final author = post['author'] as Map<String, dynamic>?;
    final isPinned = post['isPinned'] == true;

    return AnimatedPress(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(color: dark ? DesignTokens.darkBorder : DesignTokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (community != null) ...[
              if (community['icon'] != null && community['icon'].toString().isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    community['icon'].toString(),
                    height: 80, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    Text('y/${community['name']}',
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: DesignTokens.primary,
                        )),
                    const SizedBox(width: 4),
                    Text('• Posted by u/${author?['username'] ?? 'unknown'}',
                        style: TextStyle(fontSize: 11, color: DesignTokens.textTertiary)),
                    const Spacer(),
                    if (isPinned)
                      Icon(Icons.push_pin_rounded, size: 14, color: DesignTokens.warning),
                  ],
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post['flairText'] != null && post['flairText'].toString().isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(right: 6, top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: DesignTokens.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(post['flairText'].toString(),
                          style: TextStyle(fontSize: 10, color: DesignTokens.primary)),
                    ),
                  Expanded(
                    child: Text(
                      post['title']?.toString() ?? '',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (post['body'] != null && post['body'].toString().trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: Text(
                  post['body'].toString(),
                  maxLines: 3, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: DesignTokens.textSecondary),
                ),
              ),
            if (post['imageUrl'] != null && post['imageUrl'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    post['imageUrl'].toString(),
                    height: 160, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    loadingBuilder: (_, child, progress) =>
                        progress == null ? child : const ShimmerBox(height: 160, radius: 8),
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
                    downvotes: (post['fuzzedDownvotes'] as num?)?.toInt() ?? 0,
                    score: (post['fuzzedScore'] as num?)?.toInt() ?? 0,
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.chat_bubble_outline_rounded, size: 16, color: DesignTokens.textTertiary),
                  const SizedBox(width: 4),
                  Text(_count(post['commentCount']),
                      style: TextStyle(fontSize: 12, color: DesignTokens.textTertiary)),
                  const Spacer(),
                  Icon(Icons.share_outlined, size: 16, color: DesignTokens.textTertiary),
                  const SizedBox(width: 16),
                  Icon(Icons.bookmark_outline_rounded, size: 16, color: DesignTokens.textTertiary),
                ],
              ),
            ),
            if (post['isSpoiler'] == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                decoration: BoxDecoration(
                  color: DesignTokens.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('SPOILER',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: DesignTokens.warning)),
              ),
          ],
        ),
      ),
    );
  }

  String _count(dynamic val) {
    final n = (val as num?)?.toInt() ?? 0;
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}
