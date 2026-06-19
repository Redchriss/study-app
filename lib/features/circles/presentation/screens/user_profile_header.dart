import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';
import 'karma_chip.dart';

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> profile;
  final String username;
  final bool isOwnProfile;
  final bool isFollowing;
  final bool isBlocked;
  final VoidCallback? onFollow;
  final VoidCallback? onBlock;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.username,
    required this.isOwnProfile,
    required this.isFollowing,
    required this.isBlocked,
    this.onFollow,
    this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarUrl = profile['avatarUrl']?.toString();
    final bannerUrl = profile['bannerUrl']?.toString();
    final bio = profile['bio']?.toString();
    final postKarma = (profile['postKarma'] as num?)?.toInt() ?? 0;
    final commentKarma = (profile['commentKarma'] as num?)?.toInt() ?? 0;
    final awardKarma = (profile['awardKarma'] as num?)?.toInt() ?? 0;
    final totalKarma = (profile['totalKarma'] as num?)?.toInt() ?? 0;
    final createdAt = profile['createdAt']?.toString();

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            if (bannerUrl != null && bannerUrl.isNotEmpty)
              Positioned.fill(
                child: Image.network(bannerUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: DesignTokens.brandGradient))),
              )
            else
              const DecoratedBox(
                  decoration:
                      BoxDecoration(gradient: DesignTokens.brandGradient)),
            Positioned(
              left: 16,
              bottom: 60,
              child: CircleAvatar(
                radius: 36,
                backgroundColor: DesignTokens.surface,
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(36),
                        child: Image.network(avatarUrl,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.person,
                                size: 36,
                                color: DesignTokens.primary)),
                      )
                    : const Icon(Icons.person,
                        size: 36, color: DesignTokens.primary),
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(130),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('u/$username',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Row(
                children: [
                  KarmaChip(label: 'Post', value: postKarma),
                  const SizedBox(width: 8),
                  KarmaChip(label: 'Comment', value: commentKarma),
                  const SizedBox(width: 8),
                  KarmaChip(label: 'Award', value: awardKarma),
                  const Spacer(),
                  Text('$totalKarma karma',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: DesignTokens.primary)),
                ],
              ),
              if (!isOwnProfile) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (onFollow != null)
                      FilledButton.tonal(
                        onPressed: onFollow,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(isFollowing ? 'Following' : 'Follow',
                            style: const TextStyle(fontSize: 12)),
                      ),
                    const SizedBox(width: 8),
                    if (onBlock != null)
                      TextButton(
                        onPressed: onBlock,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(isBlocked ? 'Unblock' : 'Block',
                            style: const TextStyle(
                                fontSize: 12,
                                color: DesignTokens.textSecondary)),
                      ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => context.push('/home/inbox'),
                      icon: const Icon(Icons.message_outlined, size: 14),
                      label:
                          const Text('Message', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: DesignTokens.primary,
                      ),
                    ),
                  ],
                ),
              ],
              if (bio != null && bio.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(bio,
                    style: const TextStyle(
                        fontSize: 13, color: DesignTokens.textSecondary)),
              ],
              if (createdAt != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 12, color: DesignTokens.textTertiary),
                    const SizedBox(width: 4),
                    Text('Joined ${_formatDate(createdAt)}',
                        style: const TextStyle(
                            fontSize: 11, color: DesignTokens.textTertiary)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
