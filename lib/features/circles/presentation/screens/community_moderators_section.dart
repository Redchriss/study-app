import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import 'community_divider.dart';

class CommunityModeratorsSection extends StatelessWidget {
  final List<Map<String, dynamic>> moderators;
  final bool dark;

  const CommunityModeratorsSection({
    super.key,
    required this.moderators,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CommunityDivider(dark: dark),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Text(
            'Moderators',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Column(
            children: moderators.map((m) {
              final user = m['user'] as Map<String, dynamic>?;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.shield_rounded,
                        size: 14, color: DesignTokens.primary),
                    const SizedBox(width: 6),
                    Text(
                      'u/${user?['username'] ?? 'unknown'}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
