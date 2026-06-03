import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class ClassicCommunityAvatar extends StatelessWidget {
  final Map<String, dynamic>? community;
  const ClassicCommunityAvatar({super.key, this.community});

  @override
  Widget build(BuildContext context) {
    final icon = community?['icon']?.toString() ?? '';
    final name = community?['name']?.toString() ?? '?';
    return CircleAvatar(
      radius: 8,
      backgroundColor: DesignTokens.primary.withValues(alpha: 0.15),
      backgroundImage: icon.isNotEmpty ? NetworkImage(icon) : null,
      onBackgroundImageError: icon.isNotEmpty ? (_, __) {} : null,
      child: icon.isEmpty
          ? Text(name[0].toUpperCase(),
              style: const TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  color: DesignTokens.primary))
          : null,
    );
  }
}
