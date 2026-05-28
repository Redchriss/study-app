import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

/// Overlay shown when a post is removed. Tap to reveal original content.
class RemovedOverlay extends StatelessWidget {
  final VoidCallback onReveal;
  const RemovedOverlay({super.key, required this.onReveal});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onReveal,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          color: Colors.grey.withValues(alpha: 0.08),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.visibility_off_rounded,
                  size: 32, color: Colors.grey),
              const SizedBox(height: 8),
              const Text('[removed]',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey)),
              const SizedBox(height: 4),
              Text('Tap to view original',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ),
    );
  }
}

/// [deleted] body indicator.
class DeletedBody extends StatelessWidget {
  const DeletedBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('[deleted]',
            style: TextStyle(
                fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic)),
      ),
    );
  }
}

/// Spoiler / NSFW media with blur overlay. Tap to reveal.
class SpoilerNsfwMedia extends StatelessWidget {
  final String imageUrl;
  final bool isSpoiler;
  final bool isNsfw;
  final VoidCallback onReveal;
  const SpoilerNsfwMedia({
    super.key,
    required this.imageUrl,
    required this.isSpoiler,
    required this.isNsfw,
    required this.onReveal,
  });

  @override
  Widget build(BuildContext context) {
    final label = isNsfw ? 'NSFW — Tap to view' : 'Spoiler — Tap to view';
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Image.network(
                  imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              onTap: onReveal,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
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
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
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

/// Plain (non-spoiler, non-nsfw) post media.
class PlainMedia extends StatelessWidget {
  final String imageUrl;
  const PlainMedia({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: Image.network(
        imageUrl,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : const ShimmerBox(height: 160, radius: 8),
      ),
    );
  }
}

/// Spoiler badge shown below the post content.
class SpoilerBadge extends StatelessWidget {
  const SpoilerBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      decoration: BoxDecoration(
        color: DesignTokens.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text('SPOILER',
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: DesignTokens.warning)),
    );
  }
}

/// Formats a count for display (e.g. 1200 → "1.2k").
String formatCount(dynamic val) {
  final n = (val as num?)?.toInt() ?? 0;
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return n.toString();
}
