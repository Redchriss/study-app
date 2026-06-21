import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class ProfileHeader extends StatelessWidget {
  final String? avatarUrl, bannerUrl;
  final String username;
  final String? bio;
  final String? educationLevel;
  final int? standard;
  final int? form;
  final String? universityName;
  final String? programName;
  final int postKarma, commentKarma, awardKarma, totalKarma;
  final String? createdAt;
  final bool isOwnProfile;
  final int followers, following;
  final VoidCallback? onFollow, onBlock;

  const ProfileHeader({
    super.key,
    this.avatarUrl,
    this.bannerUrl,
    required this.username,
    this.bio,
    this.educationLevel,
    this.standard,
    this.form,
    this.universityName,
    this.programName,
    required this.postKarma,
    required this.commentKarma,
    required this.awardKarma,
    required this.totalKarma,
    this.createdAt,
    required this.isOwnProfile,
    this.followers = 0,
    this.following = 0,
    this.onFollow,
    this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            if (bannerUrl != null && bannerUrl!.isNotEmpty)
              Positioned.fill(
                child: Image.network(bannerUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        color: DesignTokens.primary.withValues(alpha: 0.2))),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DesignTokens.primary.withValues(alpha: 0.3),
                      DesignTokens.primary.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            Positioned(
              left: 16,
              bottom: 60,
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                child: CircleAvatar(
                  radius: 37,
                  backgroundColor: DesignTokens.surface,
                  backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                      ? NetworkImage(avatarUrl!)
                      : null,
                  child: avatarUrl == null || avatarUrl!.isEmpty
                      ? Text(
                          username.isNotEmpty ? username[0].toUpperCase() : 'U',
                          style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: DesignTokens.primary))
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(160),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('u/$username',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _KarmaChip(label: 'Post', value: postKarma),
                  const SizedBox(width: 6),
                  _KarmaChip(label: 'Comment', value: commentKarma),
                  const SizedBox(width: 6),
                  _KarmaChip(label: 'Award', value: awardKarma),
                  const Spacer(),
                  Text('$totalKarma karma',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: DesignTokens.primary)),
                ],
              ),
              if (followers > 0 || following > 0) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('$followers followers',
                        style: const TextStyle(
                            fontSize: 12, color: DesignTokens.textSecondary)),
                    const SizedBox(width: 12),
                    Text('$following following',
                        style: const TextStyle(
                            fontSize: 12, color: DesignTokens.textSecondary)),
                  ],
                ),
              ],
              if (_educationLabel != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _educationColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: _educationColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_educationIcon,
                          size: 14, color: _educationColor),
                      const SizedBox(width: 6),
                      Text(_educationLabel!,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _educationColor)),
                    ],
                  ),
                ),
              ],
              if (bio != null && bio!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(bio!,
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
                    Text('Joined ${_formatDate(createdAt!)}',
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

  String? get _educationLabel {
    if (educationLevel == 'primary' && standard != null) {
      return 'Primary \u2022 Standard $standard';
    }
    if (educationLevel == 'secondary' && form != null) {
      return 'Secondary \u2022 Form $form';
    }
    if (educationLevel == 'tertiary') {
      if (universityName != null && programName != null) {
        return '$universityName \u2022 $programName';
      }
      if (universityName != null) return universityName;
      if (programName != null) return programName;
      return 'University';
    }
    return null;
  }

  Color get _educationColor {
    switch (educationLevel) {
      case 'primary':
        return DesignTokens.accent;
      case 'secondary':
        return DesignTokens.primary;
      case 'tertiary':
        return const Color(0xFF7A4D9E);
      default:
        return DesignTokens.textSecondary;
    }
  }

  IconData get _educationIcon {
    switch (educationLevel) {
      case 'primary':
        return Icons.child_care_rounded;
      case 'secondary':
        return Icons.school_rounded;
      case 'tertiary':
        return Icons.account_balance_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

class _KarmaChip extends StatelessWidget {
  final String label;
  final int value;
  const _KarmaChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: DesignTokens.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label: $value',
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: DesignTokens.primary)),
    );
  }
}
