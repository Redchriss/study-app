import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/widgets.dart';
import 'profile_list_widgets.dart';

class ProfileAccountSection extends ConsumerWidget {
  const ProfileAccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SectionLabel(label: 'MY ACCOUNT'),
        const SizedBox(height: 10),
        GlassCard(
          child: Column(
            children: [
              NavRow(
                  icon: Icons.edit_outlined,
                  label: 'Edit Profile',
                  onTap: () => context.push('/edit-profile')),
              const SectionDivider(),
              NavRow(
                  icon: Icons.auto_awesome_outlined,
                  label: 'Plans & Credits',
                  onTap: () => context.push('/upgrade')),
              const SectionDivider(),
              NavRow(
                  icon: Icons.emoji_events_outlined,
                  label: 'Leaderboard',
                  onTap: () => context.push('/leaderboard')),
              const SectionDivider(),
              NavRow(
                  icon: Icons.history_outlined,
                  label: 'Study History',
                  onTap: () => context.push('/history')),
            ],
          ),
        ),
      ],
    );
  }
}
