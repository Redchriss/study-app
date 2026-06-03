import 'package:flutter/material.dart';
import '../../kids_visual_theme.dart';

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
