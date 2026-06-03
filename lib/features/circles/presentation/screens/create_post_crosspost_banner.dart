part of 'create_post_screen.dart';

class _CrosspostBanner extends StatelessWidget {
  final Map<String, dynamic> post;
  const _CrosspostBanner({required this.post});

  @override
  Widget build(BuildContext context) {
    final author = post['author'] as Map<String, dynamic>?;
    final community = post['community'] as Map<String, dynamic>?;
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DesignTokens.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.repeat_rounded,
              size: 20, color: DesignTokens.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Crossposting',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: DesignTokens.primary)),
                const SizedBox(height: 2),
                Text(post['title']?.toString() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                    'by u/${author?['username'] ?? 'unknown'} in y/${community?['name'] ?? ''}',
                    style: const TextStyle(
                        fontSize: 11, color: DesignTokens.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
