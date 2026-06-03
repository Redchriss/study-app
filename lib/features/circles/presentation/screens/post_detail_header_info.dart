import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class PostHeaderInfo extends StatelessWidget {
  final Map<String, dynamic> post;
  const PostHeaderInfo({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final author = post['author'] as Map<String, dynamic>?;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post['flairText'] != null &&
              post['flairText'].toString().isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: DesignTokens.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (post['flairEmoji'] != null &&
                      post['flairEmoji'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(post['flairEmoji'].toString(),
                          style: const TextStyle(fontSize: 12)),
                    ),
                  Text(post['flairText'].toString(),
                      style: TextStyle(
                          fontSize: 10,
                          color: DesignTokens.primary,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Text(post['title']?.toString() ?? '',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 14, color: DesignTokens.textTertiary),
              const SizedBox(width: 4),
              Text('u/${author?['username'] ?? 'unknown'}',
                  style: const TextStyle(
                      fontSize: 12, color: DesignTokens.textSecondary)),
              const SizedBox(width: 8),
              const Icon(Icons.access_time_rounded,
                  size: 12, color: DesignTokens.textTertiary),
              const SizedBox(width: 4),
              Text(_timeAgo(post['createdAt']?.toString() ?? ''),
                  style: const TextStyle(
                      fontSize: 11, color: DesignTokens.textTertiary)),
              if (post['isOc'] == true) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: DesignTokens.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('OC',
                      style: TextStyle(
                          fontSize: 9,
                          color: DesignTokens.success,
                          fontWeight: FontWeight.w700)),
                ),
              ],
              if (post['isSpoiler'] == true) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: DesignTokens.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('SPOILER',
                      style: TextStyle(
                          fontSize: 9,
                          color: DesignTokens.warning,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${diff.inDays ~/ 7}w ago';
    } catch (_) {
      return '';
    }
  }
}

class SpoilerMediaOverlay extends StatelessWidget {
  final String imageUrl;
  final bool isSpoiler, isNsfw;
  final VoidCallback onReveal;
  const SpoilerMediaOverlay({
    super.key,
    required this.imageUrl,
    required this.isSpoiler,
    required this.isNsfw,
    required this.onReveal,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Image.network(imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              onTap: onReveal,
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isNsfw
                          ? Icons.warning_amber_rounded
                          : Icons.visibility_off_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isNsfw ? 'NSFW — Tap to view' : 'Spoiler — Tap to view',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
