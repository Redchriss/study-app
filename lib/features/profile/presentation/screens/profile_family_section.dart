import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import 'profile_list_widgets.dart';

class ProfileFamilySection extends ConsumerWidget {
  const ProfileFamilySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SectionLabel(label: 'FAMILY'),
        const SizedBox(height: 10),
        GlassCard(
          child: Column(
            children: [
              NavRow(
                  icon: Icons.child_care_outlined,
                  label: 'Kids Mode',
                  badge: 'Safe',
                  badgeColor: DesignTokens.success,
                  onTap: () => context.push('/kids')),
              const SectionDivider(),
              NavRow(
                  icon: Icons.family_restroom_outlined,
                  label: 'Kids Progress',
                  onTap: () => context.push('/kids/progress')),
            ],
          ),
        ),
      ],
    );
  }
}
