import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import 'about_hero.dart';
import 'about_team.dart';
import 'about_widgets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          dark ? DesignTokens.darkBackground : DesignTokens.background,
      body: CustomScrollView(
        slivers: [
          const AboutHero(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Version chip
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: DesignTokens.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: DesignTokens.primary.withValues(alpha: 0.2)),
                    ),
                    child: const Text(
                      'Version 1.0.0 · Beta',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                TeamSection(dark: dark),
                const SizedBox(height: 28),

                // ── Mission ───────────────────────────────────────────────
                const SectionLabel('Our Mission'),
                const SizedBox(height: 10),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  DesignTokens.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.flag_rounded,
                                color: DesignTokens.primary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Bridging the Education Gap',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: dark
                                    ? DesignTokens.darkTextPrimary
                                    : DesignTokens.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Yaza exists to make quality education accessible to every Malawian '
                        'student — regardless of their school, location, or background. '
                        'We use AI to deliver personalised tutoring, exam prep, and study '
                        'materials that actually match how students in Malawi learn.',
                        style: TextStyle(
                            color: DesignTokens.textSecondary,
                            height: 1.65,
                            fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Features ──────────────────────────────────────────────
                const SectionLabel('What Yaza Does'),
                const SizedBox(height: 10),
                const GlassCard(
                  child: Column(
                    children: [
                      FeatureRow(
                          icon: Icons.psychology_rounded,
                          color: DesignTokens.primary,
                          title: 'Agent',
                          description:
                              'Get AI-powered explanations tailored to your education level.'),
                      FeatureRow(
                          icon: Icons.document_scanner_rounded,
                          color: DesignTokens.accent,
                          title: 'Smart Scanner',
                          description:
                              'Snap a photo of any question and get step-by-step solutions.'),
                      FeatureRow(
                          icon: Icons.quiz_rounded,
                          color: Color(0xFF8E44AD),
                          title: 'Practice Quizzes',
                          description:
                              'Adaptive quizzes that focus on your weak spots.'),
                      FeatureRow(
                          icon: Icons.child_friendly_rounded,
                          color: Color(0xFFF39C12),
                          title: 'Kids Mode',
                          description:
                              'Illustrated visual lessons and fun quizzes for younger learners.'),
                      FeatureRow(
                          icon: Icons.group_rounded,
                          color: DesignTokens.secondary,
                          title: 'Study Circles',
                          description:
                              'Collaborate and study together with classmates.'),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Footer ────────────────────────────────────────────────
                const Center(
                  child: Column(
                    children: [
                      Text(
                        'Made with \u2764\ufe0f in Malawi',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: DesignTokens.textSecondary),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '\u00a9 2025 Yaza. All rights reserved.',
                        style: TextStyle(
                            fontSize: 12, color: DesignTokens.textTertiary),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
