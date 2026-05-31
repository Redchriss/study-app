import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/widgets.dart';
import 'profile_list_widgets.dart';

class ProfileAboutSection extends ConsumerWidget {
  const ProfileAboutSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      child: Column(
        children: [
          NavRow(
              icon: Icons.info_outline,
              label: 'About Yaza',
              onTap: () => context.push('/about')),
          const SectionDivider(),
          NavRow(
              icon: Icons.gavel_outlined,
              label: 'Terms of Service',
              onTap: () => context.push('/legal/terms')),
          const SectionDivider(),
          NavRow(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              onTap: () => context.push('/legal/privacy')),
          const SectionDivider(),
          NavRow(
              icon: Icons.help_outline_rounded,
              label: 'FAQ',
              onTap: () => context.push('/legal/faq')),
          const SectionDivider(),
          NavRow(
              icon: Icons.support_agent_outlined,
              label: 'Support & Contact',
              onTap: () => context.push('/legal/support')),
        ],
      ),
    );
  }
}
