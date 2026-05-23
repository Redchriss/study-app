import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import 'vote_buttons.dart';

enum PostCardLayout { compact, card, classic }

class PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final PostCardLayout layout;
  final VoidCallback onTap;

  const PostCard({
    super.key,
    required this.post,
    this.layout = PostCardLayout.card,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    switch (layout) {
      case PostCardLayout.compact:
        return _CompactPostCard(post: post, onTap: onTap);
      case PostCardLayout.card:
        return _CardPostCard(post: post, onTap: onTap);
      case PostCardLayout.classic:
        return _ClassicPostCard(post: post, onTap: onTap);
    }
  }
}

class _CardPostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onTap;
  const _CardPostCard({required this.post, required this.onTap});

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
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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

class _CompactPostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onTap;
  const _CompactPostCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final community = post['community'] as Map<String, dynamic>?;
    final author = post['author'] as Map<String, dynamic>?;

    return AnimatedPress(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: DesignTokens.border.withValues(alpha: 0.5))),
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
                  Text(
                    post['title']?.toString() ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'y/${community?['name'] ?? '?'} • u/${author?['username'] ?? '?'}',
                    style: TextStyle(fontSize: 11, color: DesignTokens.textTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(_count(post['commentCount']),
                style: TextStyle(fontSize: 12, color: DesignTokens.textTertiary)),
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

class _ClassicPostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onTap;
  const _ClassicPostCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedPress(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? DesignTokens.darkSurface : DesignTokens.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(color: DesignTokens.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 64, height: 64,
                child: post['imageUrl'] != null && post['imageUrl'].toString().isNotEmpty
                    ? Image.network(post['imageUrl'].toString(), fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderIcon())
                    : _placeholderIcon(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post['title']?.toString() ?? '',
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    '${_count((post['fuzzedScore'] as num?)?.toInt() ?? 0)} pts • ${_count(post['commentCount'])} comments',
                    style: TextStyle(fontSize: 11, color: DesignTokens.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderIcon() => Container(
    color: DesignTokens.surfaceVariant,
    child: Icon(Icons.article_outlined, color: DesignTokens.textTertiary, size: 28),
  );

  String _count(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}
