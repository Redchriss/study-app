import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class GalleryCarousel extends StatefulWidget {
  final List galleryItems;
  const GalleryCarousel({super.key, required this.galleryItems});

  @override
  State<GalleryCarousel> createState() => _GalleryCarouselState();
}

class _GalleryCarouselState extends State<GalleryCarousel> {
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
                final linkUrl = item?['linkUrl']?.toString() ?? '';
                return Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: linkUrl.isNotEmpty
                            ? () => launchUrl(Uri.parse(linkUrl))
                            : null,
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

class VideoPlayerPlaceholder extends StatelessWidget {
  final String videoUrl;
  final dynamic videoDuration;
  const VideoPlayerPlaceholder(
      {super.key, required this.videoUrl, this.videoDuration});

  Future<void> _playVideo(BuildContext context) async {
    final uri = Uri.tryParse(videoUrl);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final durationStr = videoDuration?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () => _playVideo(context),
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
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('▶ Tap to play',
                        style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
