import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class PostLinkPreview extends StatelessWidget {
  final Map<String, dynamic> post;
  const PostLinkPreview({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final url = post['url']?.toString() ?? '';
    final domain = post['urlDomain']?.toString() ?? '';
    final thumbnail = post['urlThumbnail']?.toString() ?? '';
    final urlDescription = post['urlDescription']?.toString() ?? '';

    // Check for Yaza app URLs to show rich embedded cards
    final yazaMatch =
        RegExp(r'yaza\.app\/(quiz|material|paper)\/').firstMatch(url);

    if (yazaMatch != null) {
      return _buildYazaCard(context, yazaMatch, post);
    }

    // Generic link preview
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.border),
      ),
      child: Row(
        children: [
          if (thumbnail.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(thumbnail,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          if (thumbnail.isNotEmpty) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post['title']?.toString() ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                if (urlDescription.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(urlDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: DesignTokens.textSecondary)),
                  ),
                if (domain.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(domain,
                        style: const TextStyle(
                            fontSize: 11, color: DesignTokens.textTertiary)),
                  ),
              ],
            ),
          ),
          const Icon(Icons.open_in_new,
              size: 16, color: DesignTokens.textTertiary),
        ],
      ),
    );
  }

  Widget _buildYazaCard(
      BuildContext context, RegExpMatch yazaMatch, Map<String, dynamic> post) {
    final type = yazaMatch.group(1);
    String typeLabel;
    IconData typeIcon;
    Color typeColor;
    switch (type) {
      case 'quiz':
        typeLabel = 'Quiz';
        typeIcon = Icons.quiz_outlined;
        typeColor = DesignTokens.warning;
        break;
      case 'material':
        typeLabel = 'Material';
        typeIcon = Icons.menu_book_outlined;
        typeColor = DesignTokens.success;
        break;
      case 'paper':
        typeLabel = 'Paper';
        typeIcon = Icons.description_outlined;
        typeColor = DesignTokens.info;
        break;
      default:
        typeLabel = 'Link';
        typeIcon = Icons.link;
        typeColor = DesignTokens.primary;
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.border),
        gradient: LinearGradient(
          colors: [typeColor.withValues(alpha: 0.05), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(typeIcon, color: typeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post['title']?.toString() ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('  $typeLabel',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: typeColor)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.open_in_new,
              size: 16, color: DesignTokens.textTertiary),
        ],
      ),
    );
  }
}
