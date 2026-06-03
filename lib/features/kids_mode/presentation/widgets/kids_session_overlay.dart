import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../kids_visual_theme.dart';
export 'kids_session_warning_overlay.dart';
export 'kids_session_ended_screen.dart';

class KidsSessionTimerBar extends StatelessWidget {
  const KidsSessionTimerBar({
    super.key,
    required this.remainingSeconds,
    required this.durationSeconds,
  });

  final int remainingSeconds;
  final int durationSeconds;

  String _format(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final fraction =
        durationSeconds > 0 ? remainingSeconds / durationSeconds : 1.0;
    final isLow = remainingSeconds <= 300;
    final isCritical = remainingSeconds <= 60;
    return Semantics(
      label: 'Session time: ${_format(remainingSeconds)} remaining',
      liveRegion: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: fraction, end: fraction),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: value,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  color: isCritical
                      ? DesignTokens.error
                      : isLow
                          ? const Color(0xFFFFC02D)
                          : KidsVisualTheme.trailGreen,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isCritical
                        ? Icons.timer_off_rounded
                        : isLow
                            ? Icons.timer_outlined
                            : Icons.timer_rounded,
                    size: 14,
                    color: isCritical
                        ? DesignTokens.error
                        : Colors.white.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _format(remainingSeconds),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isCritical
                          ? DesignTokens.error
                          : Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class KidsSoftStopBanner extends StatelessWidget {
  const KidsSoftStopBanner({
    super.key,
    required this.remainingSeconds,
    required this.sessionDuration,
    this.onExtend,
  });

  final int remainingSeconds;
  final int sessionDuration;
  final VoidCallback? onExtend;

  String _format(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            KidsVisualTheme.sunGold.withValues(alpha: 0.2),
            const Color(0xFFFFF5E0).withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: KidsVisualTheme.sunGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined,
              color: KidsVisualTheme.sunGold, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                '${_format(remainingSeconds)} left',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: KidsVisualTheme.ink,
                ),
              ),
            ),
          ),
          if (onExtend != null)
            Semantics(
              button: true,
              label: 'Add 5 more minutes',
              child: TextButton(
                onPressed: onExtend,
                style: TextButton.styleFrom(
                  foregroundColor: KidsVisualTheme.trailGreen,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(44, 44),
                ),
                child: const Text(
                  '+5 min',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
