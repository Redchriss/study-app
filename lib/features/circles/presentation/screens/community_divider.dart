import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class CommunityDivider extends StatelessWidget {
  final bool dark;
  const CommunityDivider({super.key, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: dark ? DesignTokens.darkBorder : DesignTokens.border,
    );
  }
}
