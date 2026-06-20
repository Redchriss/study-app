import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'kid_auth_widgets.dart';
import 'kids_companion_character.dart';
import 'kids_parent_gate.dart';
import 'kids_session_overlay.dart';

class KidsHomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const KidsHomeAppBar({
    super.key,
    this.remainingSeconds,
    this.durationSeconds,
  });

  final int? remainingSeconds;
  final int? durationSeconds;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const KidsCompanionCharacter(size: 28),
          const SizedBox(width: 8),
          const Text('Yaza Kids'),
        ],
      ),
      actions: [
        if (remainingSeconds != null && durationSeconds != null)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: SizedBox(
              width: 120,
              child: KidsSessionTimerBar(
                remainingSeconds: remainingSeconds!,
                durationSeconds: durationSeconds!,
              ),
            ),
          ),
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
                  final passed = await showKidsParentGate(context);
                  if (!passed) return;
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz_rounded, size: 18),
                      SizedBox(width: 4),
                      Text('Switch',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
