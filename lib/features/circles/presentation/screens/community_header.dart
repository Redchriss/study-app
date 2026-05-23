import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class CommunityHeader extends StatelessWidget {
  final Map<String, dynamic> community;
  final bool dark;

  const CommunityHeader({super.key, required this.community, required this.dark});

  @override
  Widget build(BuildContext context) {
    final hasBanner = community['banner'] != null && community['banner'].toString().isNotEmpty;
    return Stack(
      children: [
        if (hasBanner)
          Image.network(community['banner'].toString(), fit: BoxFit.cover, width: double.infinity,
              errorBuilder: (_, __, ___) => _defaultHeader())
        else
          _defaultHeader(),
        Positioned(
          bottom: 8, left: 16,
          child: CircleAvatar(
            radius: 28,
            backgroundColor: DesignTokens.primary,
            child: community['icon'] != null && community['icon'].toString().isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.network(community['icon'].toString(), fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.group, color: Colors.white, size: 28)),
                  )
                : Text(community['name']?.toString()[0].toUpperCase() ?? 'C',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
          ),
        ),
      ],
    );
  }

  Widget _defaultHeader() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: dark
            ? [DesignTokens.darkSurfaceVariant, DesignTokens.darkSurface]
            : [DesignTokens.primaryLight.withValues(alpha: 0.3), DesignTokens.surfaceVariant],
      ),
    ),
  );
}
