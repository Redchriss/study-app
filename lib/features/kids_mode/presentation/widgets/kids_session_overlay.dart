import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../kids_visual_theme.dart';

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

class KidsSessionWarningOverlay extends StatefulWidget {
  const KidsSessionWarningOverlay({
    super.key,
    required onContinue,
    required onStop,
  })  : _onContinue = onContinue,
        _onStop = onStop;

  final VoidCallback _onContinue;
  final VoidCallback _onStop;

  @override
  State<KidsSessionWarningOverlay> createState() =>
      _KidsSessionWarningOverlayState();
}

class _KidsSessionWarningOverlayState extends State<KidsSessionWarningOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        color: Colors.black.withValues(alpha: 0.35),
        child: Center(
          child: ScaleTransition(
            scale: CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: KidsVisualTheme.sunGold.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('\u23F1\uFE0F', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Semantics(
                    header: true,
                    child: const Text(
                      '5 more minutes!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: KidsVisualTheme.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Semantics(
                    liveRegion: true,
                    child: const Text(
                      'Your session will end soon.\nFinish this activity, then take a break.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: KidsVisualTheme.inkMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          button: true,
                          label: 'Stop session now',
                          child: FilledButton.tonal(
                            onPressed: widget._onStop,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.grey.shade200,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              'Stop',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: KidsVisualTheme.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: Semantics(
                          button: true,
                          label: 'Continue for 5 more minutes',
                          child: FilledButton(
                            onPressed: widget._onContinue,
                            style: FilledButton.styleFrom(
                              backgroundColor: KidsVisualTheme.trailGreen,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              'Keep going!',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class KidsSessionEndedScreen extends StatelessWidget {
  const KidsSessionEndedScreen({
    super.key,
    required this.starsEarned,
    required this.onDismiss,
  });

  final int starsEarned;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: KidsVisualTheme.overlayOn(Theme.of(context)),
      child: Container(
        decoration: BoxDecoration(gradient: KidsVisualTheme.backgroundGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Semantics(
                  label: 'Session ended screen',
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('\uD83C\uDF1F',
                          style: TextStyle(fontSize: 80)),
                      const SizedBox(height: 16),
                      Semantics(
                        header: true,
                        child: const Text(
                          'Great job today!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: KidsVisualTheme.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          'You earned $starsEarned stars!\nCome back tomorrow for more fun.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: KidsVisualTheme.inkMuted,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          starsEarned.clamp(0, 5),
                          (_) => const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 3),
                            child: Icon(Icons.star_rounded,
                                color: KidsVisualTheme.sunGold, size: 36),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Semantics(
                        button: true,
                        label: 'Return to kids home',
                        child: FilledButton.icon(
                          onPressed: onDismiss,
                          icon: const Icon(Icons.home_rounded),
                          label: const Text('Go home'),
                          style: FilledButton.styleFrom(
                            backgroundColor: KidsVisualTheme.pathBlue,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                            textStyle: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
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
