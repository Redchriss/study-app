import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import 'community_divider.dart';

class CommunityRulesSection extends StatelessWidget {
  final List<Map<String, dynamic>> rules;
  final bool dark;

  const CommunityRulesSection({
    super.key,
    required this.rules,
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
            'Rules',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Column(
            children: rules.asMap().entries.map((e) {
              final r = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${e.key + 1}.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: dark
                            ? DesignTokens.darkTextPrimary
                            : DesignTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r['title']?.toString() ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: dark
                                  ? DesignTokens.darkTextPrimary
                                  : DesignTokens.textPrimary,
                            ),
                          ),
                          if (r['description'] != null &&
                              r['description'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                r['description'].toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: dark
                                      ? DesignTokens.darkTextSecondary
                                      : DesignTokens.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
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
