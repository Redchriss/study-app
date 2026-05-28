import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import 'post_detail_link_preview.dart';
import 'post_detail_media.dart';
import 'post_detail_poll.dart';

class PostDetailHeader extends StatelessWidget {
  final Map<String, dynamic> post;
  final bool dark;
  const PostDetailHeader({super.key, required this.post, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PostHeaderInfo(post: post),
        if (post['bodyHtml'] != null && post['bodyHtml'].toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: PostMarkdownBody(bodyHtml: post['bodyHtml'].toString()),
          ),
        // IMAGE type — tappable fullscreen
        if (post['imageUrl'] != null && post['imageUrl'].toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () =>
                  _showFullscreenImage(context, post['imageUrl'].toString()),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(post['imageUrl'].toString(),
                    fit: BoxFit.contain,
                    width: double.infinity,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const ShimmerBox(height: 200)),
              ),
            ),
          ),
        // POLL type
        if (post['poll'] != null)
          PollWidget(poll: post['poll'] as Map<String, dynamic>, dark: dark),
        // GALLERY type
        if (post['galleryItems'] != null)
          GalleryCarousel(galleryItems: post['galleryItems'] as List),
        // VIDEO type
        if (post['videoUrl'] != null && post['videoUrl'].toString().isNotEmpty)
          VideoPlayerPlaceholder(
            videoUrl: post['videoUrl'].toString(),
            videoDuration: post['videoDuration'],
          ),
        // CROSSPOST type
        if (post['crosspostInfo'] != null)
          CrosspostCard(
              crosspost: post['crosspostInfo'] as Map<String, dynamic>),
        // LINK type
        if (post['url'] != null && post['url'].toString().isNotEmpty)
          PostLinkPreview(post: post),
      ],
    );
  }

  void _showFullscreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: Image.network(imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const Center(child: CircularProgressIndicator())),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostHeaderInfo extends StatelessWidget {
  final Map<String, dynamic> post;
  const _PostHeaderInfo({required this.post});

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
              child: Text(post['flairText'].toString(),
                  style: const TextStyle(
                      fontSize: 10,
                      color: DesignTokens.primary,
                      fontWeight: FontWeight.w700)),
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

class PostMarkdownBody extends StatelessWidget {
  final String bodyHtml;
  const PostMarkdownBody({super.key, required this.bodyHtml});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        dark ? DesignTokens.darkSurfaceVariant : DesignTokens.surfaceVariant;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Markdown(
        data: bodyHtml,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(
              fontSize: 14, height: 1.5, color: DesignTokens.textPrimary),
          strong: const TextStyle(fontWeight: FontWeight.w700),
          em: const TextStyle(fontStyle: FontStyle.italic),
          code: TextStyle(
            fontSize: 13,
            backgroundColor: surfaceColor,
            color: DesignTokens.primary,
          ),
          codeblockDecoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(8),
          ),
          blockquoteDecoration: BoxDecoration(
            border:
                Border(left: BorderSide(color: DesignTokens.primary, width: 3)),
            color: surfaceColor.withValues(alpha: 0.5),
          ),
          listBullet:
              const TextStyle(fontSize: 14, color: DesignTokens.textPrimary),
          h1: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
