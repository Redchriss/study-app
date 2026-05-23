import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';

class DiscoverTrendingCard extends StatelessWidget {
  final Map<String, dynamic> community;
  final bool dark;
  const DiscoverTrendingCard({super.key, required this.community, required this.dark});

  @override
  Widget build(BuildContext context) {
    final name = community['name']?.toString() ?? '';
    final displayName = community['displayName']?.toString() ?? name;
    final description = community['description']?.toString() ?? '';
    final memberCount = (community['memberCount'] as num?)?.toInt() ?? 0;
    final icon = community['icon']?.toString() ?? '';

    return GestureDetector(
      onTap: () => context.push('/y/$name'),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DesignTokens.border.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: DesignTokens.primary.withValues(alpha: 0.1),
                  backgroundImage: icon.isNotEmpty ? NetworkImage(icon) : null,
                  child: icon.isEmpty
                      ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(color: DesignTokens.primary, fontWeight: FontWeight.w700))
                      : null,
                ),
                const Spacer(),
                Text('y/$name',
                    style: TextStyle(fontSize: 10, color: DesignTokens.primary, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(displayName,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            if (description.isNotEmpty)
              Text(description,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: DesignTokens.textSecondary)),
            const Spacer(),
            Text('${_formatCount(memberCount)} members',
                style: TextStyle(fontSize: 10, color: DesignTokens.textTertiary)),
          ],
        ),
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}
