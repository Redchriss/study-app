import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class PreferenceSectionHeader extends StatelessWidget {
  final String title;
  const PreferenceSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: DesignTokens.textSecondary)),
    );
  }
}
