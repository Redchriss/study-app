import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../kids_visual_theme.dart';
import 'kid_auth_widgets.dart';

class KidsHomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const KidsHomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: DesignTokens.shadowSm(theme.brightness == Brightness.dark),
            ),
            child: const Icon(Icons.school_rounded, color: KidsVisualTheme.pathBlue, size: 22),
          ),
          const SizedBox(width: 10),
          const Text('Yaza Kids'),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
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
                ref.read(kidAuthStateProvider.notifier).state = const KidAuthState();
                if (context.mounted) context.go('/kids');
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text('Switch', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
