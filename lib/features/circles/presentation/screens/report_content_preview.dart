import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_tokens.dart';

class ContentPreview extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isPost;
  final String communitySlug;

  const ContentPreview({
    super.key,
    required this.item,
    required this.isPost,
    required this.communitySlug,
  });

  @override
  Widget build(BuildContext context) {
    final content =
        isPost ? item['title']?.toString() : item['body']?.toString();
    final author =
        (item['author'] as Map<String, dynamic>?)?['username']?.toString();
    final icon = isPost ? Icons.article_outlined : Icons.comment_outlined;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: InkWell(
        onTap: isPost
            ? () => context.push('/y/$communitySlug/post/${item['slug']}')
            : null,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: DesignTokens.surfaceVariant,
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: DesignTokens.textTertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (content != null)
                      Text(
                        content,
                        maxLines: isPost ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    if (author != null)
                      Text(
                        'u/$author',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DesignTokens.textTertiary, fontSize: 11),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
