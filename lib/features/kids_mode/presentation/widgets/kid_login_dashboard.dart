import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../kids_visual_theme.dart';
import 'kids_companion_character.dart';
import 'kids_playful_button.dart';

class KidLoginDashboard extends StatelessWidget {
  const KidLoginDashboard({
    super.key,
    required this.children,
    required this.avatars,
    required this.parentToken,
    required this.onCreateKid,
    required this.onLoginKid,
    required this.onLogout,
  });

  final List<dynamic>? children;
  final Map<String, String> avatars;
  final String? parentToken;
  final VoidCallback onCreateKid;
  final void Function(Map<String, dynamic>) onLoginKid;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasChildren = children != null && children!.isNotEmpty;
    return Theme(
      data: KidsVisualTheme.overlayOn(theme),
      child: Container(
        decoration: BoxDecoration(gradient: KidsVisualTheme.backgroundGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                KidsCompanionCharacter(size: 32),
                const SizedBox(width: 8),
                const Text('Who is learning?'),
              ],
            ),
            actions: [
              Semantics(
                button: true,
                label: 'Add a new child learner',
                child: IconButton(
                  tooltip: 'Add child',
                  onPressed: onCreateKid,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: KidsVisualTheme.pathBlue),
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'Sign out of parent account',
                child: IconButton(
                  tooltip: 'Sign out',
                  onPressed: onLogout,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.logout_rounded,
                        color: KidsVisualTheme.inkMuted),
                  ),
                ),
              ),
            ],
          ),
          body: children == null
              ? const LoadingWidget()
              : hasChildren
                  ? ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: children!.length + 1,
                      itemBuilder: (_, i) {
                        if (i == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Center(
                              child: KidsCompanionMessage(
                                message: children!.length == 1
                                    ? 'Tap your profile to start learning!'
                                    : 'Choose your profile to begin!',
                              ),
                            ),
                          );
                        }
                        final kid = children![i - 1] as Map<String, dynamic>;
                        final name = kid['childName'] as String? ?? 'Learner';
                        final kidId = kid['id']?.toString() ?? '';
                        final avatar = avatars[kidId] ?? '';
                        final isEcd = kid['childEducationTrack'] == 'ecd';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Semantics(
                            button: true,
                            label: 'Sign in as $name',
                            child: Material(
                              color: Colors.white.withValues(alpha: 0.96),
                              borderRadius: BorderRadius.circular(22),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(22),
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  onLoginKid(kid);
                                },
                                child: Container(
                                  constraints: const BoxConstraints(minHeight: 72),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          gradient: KidsVisualTheme.ctaGradient,
                                          borderRadius: BorderRadius.circular(18),
                                          boxShadow: KidsVisualTheme.chunkyShadow(
                                              const Color(0xFF2A8F4A),
                                              dy: 3),
                                        ),
                                        child: Center(
                                          child: Text(
                                            avatar.isNotEmpty ? avatar : name[0].toUpperCase(),
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: avatar.isNotEmpty ? 32 : 24,
                                                fontWeight: FontWeight.w900),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name,
                                                style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w800,
                                                    color: KidsVisualTheme.ink)),
                                            const SizedBox(height: 4),
                                            Text(
                                              isEcd
                                                  ? 'Early Childhood \u00b7 Std ${kid['standard'] ?? '?'}'
                                                  : 'Primary \u00b7 Std ${kid['standard'] ?? '?'}',
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: KidsVisualTheme.inkMuted),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: KidsVisualTheme.pathBlue.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.play_circle_fill_rounded,
                                            color: KidsVisualTheme.pathBlue,
                                            size: 32),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  shape: BoxShape.circle,
                                  boxShadow: DesignTokens.shadowSm(
                                      theme.brightness == Brightness.dark)),
                              child: const Icon(Icons.child_friendly_rounded,
                                  size: 64,
                                  color: KidsVisualTheme.pathBlue),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Add your first learner',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Create a profile and PIN so your child can open Yaza Kids on their own.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontSize: 15,
                                  height: 1.4,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 28),
                            KidsPlayfulPrimaryButton(
                                label: 'Add a child',
                                icon: Icons.add_rounded,
                                onTap: onCreateKid),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }
}
