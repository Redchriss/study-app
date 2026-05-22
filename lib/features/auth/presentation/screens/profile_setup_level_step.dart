import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import 'profile_step_card.dart';

class ProfileLevelStep extends StatelessWidget {
  final VoidCallback onSelectPrimary;
  final VoidCallback onSelectSecondary;
  final VoidCallback onSelectTertiary;

  const ProfileLevelStep({
    super.key,
    required this.onSelectPrimary,
    required this.onSelectSecondary,
    required this.onSelectTertiary,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        Text('What level are you?',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DesignTokens.info.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: DesignTokens.info.withValues(alpha: 0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.child_care_outlined,
                  color: DesignTokens.info, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kids (under a parent account with PIN) are not chosen here '
                  '— after setup, open Profile → Kids mode.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(height: 1.35, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ProfileLevelCard(
          icon: Icons.child_care_rounded,
          title: 'Primary school',
          subtitle: 'Standards 1–8 · PSLCE path',
          color: const Color(0xFFE87E5E),
          dark: dark,
          onTap: onSelectPrimary,
        ),
        const SizedBox(height: 16),
        ProfileLevelCard(
          icon: Icons.menu_book_rounded,
          title: 'Secondary school',
          subtitle: 'Forms 1–4 · JCE & MSCE',
          color: const Color(0xFF389E75),
          dark: dark,
          onTap: onSelectSecondary,
        ),
        const SizedBox(height: 16),
        ProfileLevelCard(
          icon: Icons.account_balance_rounded,
          title: 'University / college',
          subtitle: 'UNIMA, MUBAS, MUST, TTCs, private colleges…',
          color: const Color(0xFF5A6BB2),
          dark: dark,
          onTap: onSelectTertiary,
        ),
      ],
    );
  }
}
