import 'package:flutter/material.dart';

import '../../kids_visual_theme.dart';

class KidsOfflineBanner extends StatelessWidget {
  const KidsOfflineBanner({super.key, this.isOffline = false});

  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      label: 'You are offline. Downloaded content is available.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: KidsVisualTheme.sunGold.withValues(alpha: 0.15),
          border: Border(
            bottom: BorderSide(
              color: KidsVisualTheme.sunGold.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 16,
              color: KidsVisualTheme.sunGold.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Offline \u2014 playing from saved content',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: KidsVisualTheme.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
