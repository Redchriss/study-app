import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('About Yaza', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.spMd),
        child: Column(
          children: [
            const SizedBox(height: DesignTokens.spLg),
            // App icon
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [DesignTokens.primary, DesignTokens.accent]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 48),
            ),
            const SizedBox(height: DesignTokens.spMd),
            Text('Yaza', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
            Text('AI Study Companion for Malawian Students', style: TextStyle(color: DesignTokens.textSecondary)),
            const SizedBox(height: DesignTokens.spSm),
            Text('v1.0.0', style: TextStyle(color: DesignTokens.textTertiary, fontSize: 12)),

            const SizedBox(height: DesignTokens.spXl),

            // ── Creator: Redson ──────────────────────────────────────
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Meet the Team', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: DesignTokens.spMd),
                  _TeamMember(
                    name: 'Redson Ngwira',
                    role: 'Founder & Developer',
                    twitter: 'RedsonNgwira',
                    bio: 'Building Yaza to help every Malawian student access quality education through AI.',
                    color: DesignTokens.primary,
                  ),
                  const Divider(height: DesignTokens.spXl),
                  _TeamMember(
                    name: 'Yankho Mtewa',
                    role: 'Co-Founder',
                    twitter: null,
                    bio: 'Working to make education accessible and affordable for all Malawians.',
                    color: DesignTokens.accent,
                  ),
                ],
              ),
            ),

            const SizedBox(height: DesignTokens.spMd),

            // ── Mission ─────────────────────────────────────────────
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Our Mission', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: DesignTokens.spSm),
                  Text(
                    'Yaza exists to bridge the education gap in Malawi. '
                    'We use AI to make exam preparation, study materials, and tutoring '
                    'accessible to every student — regardless of their school or location.',
                    style: TextStyle(color: DesignTokens.textSecondary, height: 1.6),
                  ),
                ],
              ),
            ),

            const SizedBox(height: DesignTokens.spLg),
            Text('Made with ❤️ in Malawi', style: TextStyle(color: DesignTokens.textTertiary)),
            const SizedBox(height: DesignTokens.spXxl),
          ],
        ),
      ),
    );
  }
}

class _TeamMember extends StatelessWidget {
  final String name;
  final String role;
  final String? twitter;
  final String bio;
  final Color color;

  const _TeamMember({
    required this.name,
    required this.role,
    this.twitter,
    required this.bio,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: Center(
                child: Text(
                  name.split(' ').map((e) => e[0]).join(),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.spMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  Text(role, style: TextStyle(color: DesignTokens.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            if (twitter != null)
              GestureDetector(
                onTap: () async {
                  final uri = Uri.parse('https://twitter.com/$twitter');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.alternate_email, color: color, size: 20),
                ),
              ),
          ],
        ),
        const SizedBox(height: DesignTokens.spSm),
        Text(bio, style: TextStyle(color: DesignTokens.textSecondary, fontSize: 13, height: 1.4)),
      ],
    );
  }
}
