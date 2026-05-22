import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../kids_visual_theme.dart';
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
            title: const Text('Who is learning?'),
            actions: [
              IconButton(
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
              IconButton(
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
            ],
          ),
          body: children == null
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : hasChildren
                  ? ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: children!.length,
                      itemBuilder: (_, i) {
                        final kid = children![i] as Map<String, dynamic>;
                        final name = kid['childName'] as String? ?? 'Learner';
                        final kidId = kid['id']?.toString() ?? '';
                        final avatar = avatars[kidId] ?? '';
                        final letter =
                            name.isNotEmpty ? name[0].toUpperCase() : '?';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: Colors.white.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(22),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(22),
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                onLoginKid(kid);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        gradient: KidsVisualTheme.ctaGradient,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: KidsVisualTheme.chunkyShadow(
                                            const Color(0xFF2A8F4A),
                                            dy: 3),
                                      ),
                                      child: Center(
                                        child: Text(
                                          avatar.isNotEmpty ? avatar : letter,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize:
                                                  avatar.isNotEmpty ? 32 : 24,
                                              fontWeight: FontWeight.w900),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(name,
                                              style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w800,
                                                  color: KidsVisualTheme.ink)),
                                          const SizedBox(height: 4),
                                          Text(
                                            kid['childEducationTrack'] == 'ecd'
                                                ? 'Early childhood \u00b7 Std ${kid['standard'] ?? '?'}'
                                                : 'Primary \u00b7 Std ${kid['standard'] ?? '?'}',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    KidsVisualTheme.inkMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.play_circle_fill_rounded,
                                        color: KidsVisualTheme.pathBlue,
                                        size: 40),
                                  ],
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
                              child: Icon(Icons.child_friendly_rounded,
                                  size: 64,
                                  color: KidsVisualTheme.pathBlue
                                      .withValues(alpha: 0.85)),
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
