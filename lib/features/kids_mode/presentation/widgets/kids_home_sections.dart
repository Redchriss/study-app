import 'package:flutter/material.dart';

import '../../kids_visual_theme.dart';

class KidsReviewQueue extends StatelessWidget {
  const KidsReviewQueue({
    super.key,
    required this.reviewQueue,
    required this.onTapTopic,
  });

  final List<Map<String, dynamic>> reviewQueue;
  final ValueChanged<String> onTapTopic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E8),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ready to review',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: KidsVisualTheme.ink,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: reviewQueue.map((item) {
              final topicId = item['topicId']?.toString() ?? '';
              final state = item['state'] is Map
                  ? Map<String, dynamic>.from(item['state'] as Map)
                  : null;
              return ActionChip(
                avatar: const Icon(Icons.refresh_rounded,
                    size: 18, color: Color(0xFFF39C12)),
                label: Text(item['topicName']?.toString() ?? 'Topic'),
                onPressed: topicId.isEmpty ? null : () => onTapTopic(topicId),
                tooltip: state?['nextReviewLabel']?.toString(),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class KidsMasteryHint extends StatelessWidget {
  const KidsMasteryHint({
    super.key,
    required this.masteryLevel,
    this.reviewHint,
  });

  final int masteryLevel;
  final String? reviewHint;

  @override
  Widget build(BuildContext context) {
    final message = masteryLevel >= 4
        ? 'Amazing work. This topic is nearly mastered.'
        : masteryLevel >= 2
            ? 'Nice progress. One more strong quiz will build mastery.'
            : 'Keep practicing. Short repeat sessions help memory stick.';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology_alt_rounded,
              color: KidsVisualTheme.pathBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              reviewHint == null || reviewHint!.trim().isEmpty
                  ? message
                  : '$message ${reviewHint!.trim()}.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: KidsVisualTheme.ink,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class KidsEmptySubjects extends StatelessWidget {
  const KidsEmptySubjects({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 48, color: KidsVisualTheme.inkMuted),
          SizedBox(height: 12),
          Text(
            'Subjects could not load. Check your connection and pull to refresh from the parent app.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: KidsVisualTheme.inkMuted,
                height: 1.4),
          ),
        ],
      ),
    );
  }
}

class KidsFloatingPanel extends StatelessWidget {
  const KidsFloatingPanel({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
              color: KidsVisualTheme.pathBlue.withValues(alpha: 0.12),
              offset: const Offset(0, 8),
              blurRadius: 24),
        ],
      ),
      child: child,
    );
  }
}

class CorrectBurstOverlay extends StatelessWidget {
  const CorrectBurstOverlay({
    super.key,
    required this.controller,
  });

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -8,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final t = Curves.easeOut.transform(controller.value);
            return Opacity(
              opacity: 1.0 - t,
              child: Transform.scale(
                scale: 0.85 + 0.35 * t,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final rot = (i - 2) * 0.15 * (1 - t);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Transform.rotate(
                        angle: rot,
                        child: Icon(Icons.star_rounded,
                            size: 32 + 12 * t, color: KidsVisualTheme.sunGold),
                      ),
                    );
                  }),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
