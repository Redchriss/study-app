import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
export 'crosspost_card.dart';
export 'video_player_placeholder.dart';

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
