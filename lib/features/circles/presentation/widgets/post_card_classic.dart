import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class ClassicPostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onTap;
  const ClassicPostCard({super.key, required this.post, required this.onTap});

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

  String _count(dynamic val) {
    final n = (val as num?)?.toInt() ?? 0;
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}
