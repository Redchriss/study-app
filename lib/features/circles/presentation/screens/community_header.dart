import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class CommunityHeader extends StatelessWidget {
  final Map<String, dynamic> community;
  final bool dark;

  const CommunityHeader({
    super.key,
    required this.community,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final hasBanner = community['banner'] != null &&
        community['banner'].toString().isNotEmpty;
    final bannerColor = community['bannerColor']?.toString() ?? '#0079D3';

    return Stack(
      children: [
        if (hasBanner)
          Image.network(
            community['banner'].toString(),
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, __, ___) => _gradientBanner(bannerColor),
          )
        else
          _gradientBanner(bannerColor),
        Positioned(
          bottom: 8,
          left: 16,
          child: CircleAvatar(
            radius: 32,
            backgroundColor: DesignTokens.primary,
            child: community['icon'] != null &&
                    community['icon'].toString().isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.network(
                      community['icon'].toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.group,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  )
                : Text(
                    community['name']?.toString()[0].toUpperCase() ?? 'C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _gradientBanner(String colorHex) {
    final color = _parseColor(colorHex);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? [color.withValues(alpha: 0.6), DesignTokens.darkSurface]
              : [color.withValues(alpha: 0.4), DesignTokens.background],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final h = hex.replaceFirst('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return DesignTokens.primary;
    }
  }
}
