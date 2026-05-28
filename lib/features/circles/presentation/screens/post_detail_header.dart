import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
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
            child: _MarkdownBody(bodyHtml: post['bodyHtml'].toString()),
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
          _GalleryCarousel(galleryItems: post['galleryItems'] as List),
        // VIDEO type
        if (post['videoUrl'] != null && post['videoUrl'].toString().isNotEmpty)
          _VideoPlayerPlaceholder(
            videoUrl: post['videoUrl'].toString(),
            videoDuration: post['videoDuration'],
          ),
        // CROSSPOST type
        if (post['crosspostInfo'] != null)
          _CrosspostCard(
              crosspost: post['crosspostInfo'] as Map<String, dynamic>),
        // LINK type
        if (post['url'] != null && post['url'].toString().isNotEmpty)
          _LinkPreview(post: post),
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

class _GalleryCarousel extends StatefulWidget {
  final List galleryItems;
  const _GalleryCarousel({required this.galleryItems});

  @override
  State<_GalleryCarousel> createState() => _GalleryCarouselState();
}

class _GalleryCarouselState extends State<_GalleryCarousel> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.galleryItems.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          SizedBox(
            height: 280,
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: widget.galleryItems.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (_, i) {
                final item = widget.galleryItems[i] as Map<String, dynamic>?;
                final imageUrl = item?['imageUrl']?.toString() ?? '';
                final caption = item?['caption']?.toString() ?? '';
                return Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(imageUrl,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            loadingBuilder: (_, child, progress) =>
                                progress == null
                                    ? child
                                    : const ShimmerBox(height: 260)),
                      ),
                    ),
                    if (caption.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(caption,
                            style: const TextStyle(
                                fontSize: 12,
                                color: DesignTokens.textSecondary)),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          if (widget.galleryItems.length > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.galleryItems.length, (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == i ? 10 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? DesignTokens.primary
                        : DesignTokens.textTertiary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}

class _VideoPlayerPlaceholder extends StatelessWidget {
  final String videoUrl;
  final dynamic videoDuration;
  const _VideoPlayerPlaceholder({required this.videoUrl, this.videoDuration});

  @override
  Widget build(BuildContext context) {
    final durationStr = videoDuration?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () {},
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.play_circle_fill,
                    size: 64, color: Colors.white54),
                if (durationStr.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(durationStr,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                    ),
                  ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 48,
                  child: Text(videoUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 10)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CrosspostCard extends StatelessWidget {
  final Map<String, dynamic> crosspost;
  const _CrosspostCard({required this.crosspost});

  @override
  Widget build(BuildContext context) {
    final title = crosspost['title']?.toString() ?? '';
    final author = crosspost['author'] as Map<String, dynamic>?;
    final community = crosspost['community'] as Map<String, dynamic>?;
    final slug = crosspost['slug']?.toString() ?? '';
    final authorName = author?['username']?.toString() ?? 'unknown';
    final communitySlug = community?['slug']?.toString() ?? '';

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
              children: [
                const Icon(Icons.repeat_rounded,
                    size: 20, color: DesignTokens.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('Posted by u/$authorName',
                          style: const TextStyle(
                              fontSize: 11, color: DesignTokens.textTertiary)),
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

class _MarkdownBody extends StatelessWidget {
  final String bodyHtml;
  const _MarkdownBody({required this.bodyHtml});

  @override
  Widget build(BuildContext context) {
    // flutter_markdown is available in the project dependencies
    final dark = Theme.of(context).brightness == Brightness.dark;
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
            backgroundColor: (dark
                ? DesignTokens.darkSurfaceVariant
                : DesignTokens.surfaceVariant),
            color: DesignTokens.primary,
          ),
          codeblockDecoration: BoxDecoration(
            color: (dark
                ? DesignTokens.darkSurfaceVariant
                : DesignTokens.surfaceVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          blockquoteDecoration: BoxDecoration(
            border:
                Border(left: BorderSide(color: DesignTokens.primary, width: 3)),
            color: (dark
                    ? DesignTokens.darkSurfaceVariant
                    : DesignTokens.surfaceVariant)
                .withValues(alpha: 0.5),
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

class _LinkPreview extends StatelessWidget {
  final Map<String, dynamic> post;
  const _LinkPreview({required this.post});

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
}
