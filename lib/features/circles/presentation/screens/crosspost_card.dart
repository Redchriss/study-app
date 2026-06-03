import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';

class CrosspostCard extends StatelessWidget {
  final Map<String, dynamic> crosspost;
  const CrosspostCard({super.key, required this.crosspost});

  @override
  Widget build(BuildContext context) {
    final title = crosspost['title']?.toString() ?? '';
    final author = crosspost['author'] as Map<String, dynamic>?;
    final community = crosspost['community'] as Map<String, dynamic>?;
    final slug = crosspost['slug']?.toString() ?? '';
    final authorName = author?['username']?.toString() ?? 'unknown';
    final communitySlug = community?['slug']?.toString() ?? '';
    final imageUrl = crosspost['imageUrl']?.toString() ?? '';
    final postType = crosspost['postType']?.toString() ?? 'text';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: DesignTokens.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (communitySlug.isNotEmpty && slug.isNotEmpty) {
              context.push('/y/$communitySlug/post/$slug');
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.repeat_rounded,
                    size: 20, color: DesignTokens.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('Posted by u/$authorName',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: DesignTokens.textTertiary)),
                          const SizedBox(width: 8),
                          _PostTypeBadge(postType: postType),
                        ],
                      ),
                      if (imageUrl.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(imageUrl,
                                height: 80,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox.shrink()),
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 18, color: DesignTokens.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PostTypeBadge extends StatelessWidget {
  final String postType;
  const _PostTypeBadge({required this.postType});

  @override
  Widget build(BuildContext context) {
    final typeLabel = postType[0].toUpperCase() + postType.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: DesignTokens.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(typeLabel,
          style: const TextStyle(
              fontSize: 9,
              color: DesignTokens.primary,
              fontWeight: FontWeight.w600)),
    );
  }
}
