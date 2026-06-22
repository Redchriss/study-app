import '../../../../core/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../kids_visual_theme.dart';

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
                              backgroundColor: DesignTokens.border,
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
