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
