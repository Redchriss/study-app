import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class KidsSessionWarningBanner extends StatelessWidget {
  const KidsSessionWarningBanner({super.key, required this.remainingSeconds});

  final int remainingSeconds;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Session ending soon warning',
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: DesignTokens.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DesignTokens.error.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Semantics(
              excludeSemantics: true,
              child: const Icon(Icons.timer_off_rounded,
                  color: DesignTokens.error, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Session ending soon! ${remainingSeconds ~/ 60}:${(remainingSeconds % 60).toString().padLeft(2, '0')} left',
              style: const TextStyle(
                color: DesignTokens.error,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
