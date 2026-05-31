import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../kids_visual_theme.dart';
import 'kid_auth_widgets.dart';

class KidsHomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const KidsHomeAppBar({super.key, this.remainingSeconds});

  final int? remainingSeconds;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  String _formatTime(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLow = remainingSeconds != null && remainingSeconds! <= 120;
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow:
                  DesignTokens.shadowSm(theme.brightness == Brightness.dark),
            ),
            child: const Icon(Icons.school_rounded,
                color: KidsVisualTheme.pathBlue, size: 22),
          ),
          const SizedBox(width: 10),
          const Text('Yaza Kids'),
          if (remainingSeconds != null) ...[
            const SizedBox(width: 10),
            Semantics(
              label:
                  'Session time remaining: ${_formatTime(remainingSeconds!)}',
              liveRegion: true,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isLow
                      ? DesignTokens.error.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLow ? Icons.timer_off_rounded : Icons.timer_outlined,
                      size: 16,
                      color: isLow ? DesignTokens.error : KidsVisualTheme.ink,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(remainingSeconds!),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isLow ? DesignTokens.error : KidsVisualTheme.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Semantics(
            button: true,
            label: 'Switch to a different learner',
            child: Material(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () async {
                  HapticFeedback.lightImpact();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('kid_token');
                  await prefs.remove('kid_child_name');
                  await prefs.remove('kid_standard');
                  await prefs.remove('kid_education_track');
                  ref.read(kidTokenProvider.notifier).state = null;
                  ref.read(kidProfileProvider.notifier).state = null;
                  ref.read(kidAuthStateProvider.notifier).state =
                      const KidAuthState();
                  if (context.mounted) context.go('/kids');
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Text('Switch',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
