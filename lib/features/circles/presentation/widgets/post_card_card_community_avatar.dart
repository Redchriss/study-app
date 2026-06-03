import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class CardCommunityAvatar extends StatelessWidget {
  final Map<String, dynamic>? community;
  const CardCommunityAvatar({super.key, this.community});

  @override
  Widget build(BuildContext context) {
    final icon = community?['icon']?.toString() ?? '';
    final name = community?['name']?.toString() ?? '?';
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 10,
      backgroundColor: DesignTokens.primary.withValues(alpha: 0.15),
      backgroundImage: icon.isNotEmpty ? NetworkImage(icon) : null,
      onBackgroundImageError: icon.isNotEmpty ? (_, __) {} : null,
      child: icon.isEmpty
          ? Text(letter,
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: DesignTokens.primary))
          : null,
    );
  }
}
