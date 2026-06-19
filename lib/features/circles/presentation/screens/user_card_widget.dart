import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';

class UserCardWidget extends StatelessWidget {
  final Map<String, dynamic> profile;

  const UserCardWidget({super.key, required this.profile});

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final user = profile['user'] as Map<String, dynamic>? ?? {};
    final username = user['username']?.toString() ?? '';
    final avatarUrl = profile['avatarUrl']?.toString() ?? '';
    final bio = profile['bio']?.toString() ?? '';
    final postKarma = (profile['postKarma'] as num?)?.toInt() ?? 0;
    final commentKarma = (profile['commentKarma'] as num?)?.toInt() ?? 0;
    final totalKarma = (profile['totalKarma'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: DesignTokens.signatureSurface(dark),
      child: InkWell(
        onTap: () => context.push('/u/$username'),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor:
                  DesignTokens.primary.withAlpha((0.1 * 255).round()),
              backgroundImage:
                  avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl.isEmpty
                  ? Text(username.isNotEmpty ? username[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: DesignTokens.primary,
                          fontWeight: FontWeight.w700))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('u/$username',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(
                      '${_fmt(postKarma)} post karma • ${_fmt(commentKarma)} comment karma',
                      style: const TextStyle(
                          fontSize: 11, color: DesignTokens.textTertiary)),
                  if (bio.isNotEmpty)
                    Text(bio,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: DesignTokens.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(_fmt(totalKarma),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: DesignTokens.primary)),
          ],
        ),
      ),
    );
  }
}
