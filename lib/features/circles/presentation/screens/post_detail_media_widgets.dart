import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../core/widgets/widgets.dart';
import 'post_detail_header_info.dart';
import 'post_detail_link_preview.dart';
import 'post_detail_media.dart';
import 'post_detail_poll.dart';

class PostMediaSection extends StatelessWidget {
  final Map<String, dynamic> post;
  final bool dark, isBlurred;
  final VoidCallback onReveal;

  const PostMediaSection({
    super.key,
    required this.post,
    required this.dark,
    required this.isBlurred,
    required this.onReveal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (post['imageUrl'] != null && post['imageUrl'].toString().isNotEmpty)
          _buildImage(context),
        if (post['poll'] != null)
          PollWidget(poll: post['poll'] as Map<String, dynamic>, dark: dark),
        if (post['galleryItems'] != null) _buildGallery(context),
        if (post['videoUrl'] != null && post['videoUrl'].toString().isNotEmpty)
          _buildVideo(context),
        if (post['crosspostInfo'] != null) _buildCrosspost(context),
        if (post['url'] != null && post['url'].toString().isNotEmpty)
          PostLinkPreview(post: post),
      ],
    );
  }

  Widget _buildImage(BuildContext context) {
    final imageUrl = post['imageUrl'].toString();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: isBlurred
            ? onReveal
            : () => _showFullscreenImage(context, imageUrl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: isBlurred
              ? SpoilerMediaOverlay(
                  imageUrl: imageUrl,
                  isSpoiler: post['isSpoiler'] == true,
                  isNsfw: post['isNsfw'] == true,
                  onReveal: onReveal,
                )
              : Image.network(imageUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  loadingBuilder: (_, child, progress) =>
                      progress == null ? child : const ShimmerBox(height: 200)),
        ),
      ),
    );
  }

  Widget _buildGallery(BuildContext context) {
    final items = post['galleryItems'] as List;
    if (isBlurred) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SpoilerBlurOverlay(
          isSpoiler: post['isSpoiler'] == true,
          isNsfw: post['isNsfw'] == true,
          onReveal: onReveal,
          child: GalleryCarousel(galleryItems: items),
        ),
      );
    }
    return GalleryCarousel(galleryItems: items);
  }

  Widget _buildVideo(BuildContext context) {
    final videoUrl = post['videoUrl'].toString();
    if (isBlurred) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SpoilerBlurOverlay(
          isSpoiler: post['isSpoiler'] == true,
          isNsfw: post['isNsfw'] == true,
          onReveal: onReveal,
          child: IgnorePointer(
            child: VideoPlayerPlaceholder(
              videoUrl: videoUrl,
              videoDuration: post['videoDuration'],
            ),
          ),
        ),
      );
    }
    return VideoPlayerPlaceholder(
      videoUrl: videoUrl,
      videoDuration: post['videoDuration'],
    );
  }

  Widget _buildCrosspost(BuildContext context) {
    if (isBlurred) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SpoilerBlurOverlay(
          isSpoiler: post['isSpoiler'] == true,
          isNsfw: post['isNsfw'] == true,
          onReveal: onReveal,
          child: IgnorePointer(
            child: CrosspostCard(
                crosspost: post['crosspostInfo'] as Map<String, dynamic>),
          ),
        ),
      );
    }
    return CrosspostCard(
        crosspost: post['crosspostInfo'] as Map<String, dynamic>);
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

class SpoilerBlurOverlay extends StatelessWidget {
  final bool isSpoiler, isNsfw;
  final VoidCallback onReveal;
  final Widget child;
  const SpoilerBlurOverlay({
    super.key,
    required this.isSpoiler,
    required this.isNsfw,
    required this.onReveal,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: child,
            ),
          ),
        ),
        Positioned.fill(
          child: GestureDetector(
            onTap: onReveal,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isNsfw
                        ? Icons.warning_amber_rounded
                        : Icons.visibility_off_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isNsfw ? 'NSFW — Tap to view' : 'Spoiler — Tap to view',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
