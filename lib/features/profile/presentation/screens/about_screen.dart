import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: dark ? DesignTokens.darkBackground : DesignTokens.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero SliverAppBar ─────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1B6CA8), Color(0xFF2EC4B6)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: const Icon(Icons.school_rounded, color: Colors.white, size: 42),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Yaza',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Text(
                        'AI Study Companion for Malawi',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              title: const Text(
                'About Yaza',
                style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
              ),
              centerTitle: true,
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Version chip
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: DesignTokens.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: DesignTokens.primary.withValues(alpha: 0.2)),
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

                // ── Team ─────────────────────────────────────────────────
                const _SectionLabel('Meet the Team'),
                const SizedBox(height: 10),
                Query(
                  options: QueryOptions(
                    document: gql(kTeamMembers),
                    fetchPolicy: FetchPolicy.cacheAndNetwork,
                  ),
                  builder: (result, {fetchMore, refetch}) {
                    final members = (result.data?['teamMembers'] as List?) ?? [];

                    if (result.isLoading && members.isEmpty) {
                      // Skeleton shimmer while loading
                      return Column(
                        children: List.generate(
                          2,
                          (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ShimmerBox(height: 120, radius: DesignTokens.radiusXl),
                          ),
                        ),
                      );
                    }

                    if (members.isEmpty) {
                      // Fallback to hardcoded when backend has no data yet
                      return const _StaticTeamSection();
                    }

                    return Column(
                      children: members.asMap().entries.map((e) {
                        final m = e.value as Map<String, dynamic>;
                        final isFirst = e.key == 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: isFirst
                              ? _FounderCard(
                                  name: m['name'] as String? ?? '',
                                  role: m['role'] as String? ?? '',
                                  bio: m['bio'] as String? ?? '',
                                  photoUrl: m['photoUrl'] as String?,
                                  twitter: m['twitter'] as String? ?? '',
                                  linkedin: m['linkedin'] as String? ?? '',
                                  dark: dark,
                                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0)
                              : _TeamMemberCard(
                                  name: m['name'] as String? ?? '',
                                  role: m['role'] as String? ?? '',
                                  bio: m['bio'] as String? ?? '',
                                  photoUrl: m['photoUrl'] as String?,
                                  dark: dark,
                                ).animate(delay: (e.key * 80).ms).fadeIn(duration: 350.ms),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 28),

                // ── Mission ───────────────────────────────────────────────
                const _SectionLabel('Our Mission'),
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
                              color: DesignTokens.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.flag_rounded, color: DesignTokens.primary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Bridging the Education Gap',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: dark ? DesignTokens.darkTextPrimary : DesignTokens.textPrimary,
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
                        style: TextStyle(color: DesignTokens.textSecondary, height: 1.65, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Features ──────────────────────────────────────────────
                const _SectionLabel('What Yaza Does'),
                const SizedBox(height: 10),
                const GlassCard(
                  child: Column(
                    children: [
                      _FeatureRow(Icons.psychology_rounded, DesignTokens.primary, 'AI Tutor',
                          'Chat with an AI tutor that explains concepts in plain language.'),
                      _FeatureRow(Icons.document_scanner_rounded, DesignTokens.accent, 'Smart Scanner',
                          'Snap a photo of any question and get step-by-step solutions.'),
                      _FeatureRow(Icons.quiz_rounded, Color(0xFF8E44AD), 'Practice Quizzes',
                          'Adaptive quizzes that focus on your weak spots.'),
                      _FeatureRow(Icons.child_friendly_rounded, Color(0xFFF39C12), 'Kids Mode',
                          'Illustrated visual lessons and fun quizzes for younger learners.'),
                      _FeatureRow(Icons.group_rounded, DesignTokens.secondary, 'Study Circles',
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
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: DesignTokens.textSecondary),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '\u00a9 2025 Yaza. All rights reserved.',
                        style: TextStyle(fontSize: 12, color: DesignTokens.textTertiary),
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

// ── Static fallback (used before backend has data) ─────────────────────────────
class _StaticTeamSection extends StatelessWidget {
  const _StaticTeamSection();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        _FounderCard(
          name: 'Redson Ngwira',
          role: 'Founder & Developer',
          bio: 'Building Yaza to help every Malawian student access quality education '
              'through AI — from MSCE revision to early childhood learning.',
          photoUrl: null,
          twitter: 'RedsonNgwira',
          linkedin: '',
          dark: dark,
        ),
        const SizedBox(height: 10),
        _TeamMemberCard(
          name: 'Yankho Mtewa',
          role: 'Co-Founder',
          bio: 'Working to make education accessible and affordable for all Malawians.',
          photoUrl: null,
          dark: dark,
        ),
      ],
    );
  }
}

// ── Founder hero card ──────────────────────────────────────────────────────────
class _FounderCard extends StatelessWidget {
  final String name;
  final String role;
  final String bio;
  final String? photoUrl;
  final String twitter;
  final String linkedin;
  final bool dark;

  const _FounderCard({
    required this.name,
    required this.role,
    required this.bio,
    required this.photoUrl,
    required this.twitter,
    required this.linkedin,
    required this.dark,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B6CA8), Color(0xFF1a5490)],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar — photo if available, else initials
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2.5),
                    image: photoUrl != null && photoUrl!.isNotEmpty
                        ? DecorationImage(image: NetworkImage(photoUrl!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: photoUrl == null || photoUrl!.isEmpty
                      ? Center(
                          child: Text(
                            _initials,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          role,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              bio,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.55),
            ),
            if (twitter.isNotEmpty || linkedin.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (twitter.isNotEmpty)
                    _SocialButton(
                      label: '@$twitter',
                      icon: Icons.alternate_email,
                      onTap: () async {
                        final uri = Uri.parse('https://twitter.com/$twitter');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  if (linkedin.isNotEmpty)
                    _SocialButton(
                      label: 'LinkedIn',
                      icon: Icons.link_rounded,
                      onTap: () async {
                        final uri = Uri.parse(linkedin);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Generic team member card ───────────────────────────────────────────────────
class _TeamMemberCard extends StatelessWidget {
  final String name;
  final String role;
  final String bio;
  final String? photoUrl;
  final bool dark;

  const _TeamMemberCard({
    required this.name,
    required this.role,
    required this.bio,
    required this.photoUrl,
    required this.dark,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        border: Border.all(color: dark ? DesignTokens.darkBorder : DesignTokens.border),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: DesignTokens.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              image: photoUrl != null && photoUrl!.isNotEmpty
                  ? DecorationImage(image: NetworkImage(photoUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: photoUrl == null || photoUrl!.isEmpty
                ? Center(
                    child: Text(
                      _initials,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: DesignTokens.accent),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: dark ? DesignTokens.darkTextPrimary : DesignTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  role,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DesignTokens.accent),
                ),
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    bio,
                    style: const TextStyle(fontSize: 12, color: DesignTokens.textSecondary, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: DesignTokens.textTertiary,
      ),
    );
  }
}

// ── Feature row ────────────────────────────────────────────────────────────────
class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _FeatureRow(this.icon, this.color, this.title, this.description);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: DesignTokens.textPrimary)),
                const SizedBox(height: 2),
                Text(description,
                    style: const TextStyle(fontSize: 12, color: DesignTokens.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Social button ──────────────────────────────────────────────────────────────
class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SocialButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
