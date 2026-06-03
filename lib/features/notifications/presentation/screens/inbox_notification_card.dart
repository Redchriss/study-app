import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';

class InboxNotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onMarkRead;

  const InboxNotificationCard({
    super.key,
    required this.notification,
    required this.onMarkRead,
  });

  void _onTap(BuildContext context) {
    final notifType = notification['notifType']?.toString() ?? '';
    final community = notification['community'] as Map<String, dynamic>?;
    final communitySlug = community?['slug']?.toString();
    final post = notification['post'] as Map<String, dynamic>?;
    final postSlug = post?['slug']?.toString();

    if (notifType == 'modmail') {
      if (communitySlug != null) context.push('/y/$communitySlug/mod');
      return;
    }
    if (notifType == 'community_invite') {
      if (communitySlug != null) context.push('/y/$communitySlug');
      return;
    }
    if (postSlug != null && communitySlug != null) {
      context.push('/y/$communitySlug/post/$postSlug');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRead = notification['isRead'] == true;
    final notifType = notification['notifType']?.toString() ?? '';
    final bodyPreview = notification['bodyPreview']?.toString() ?? '';
    final community = notification['community'] as Map<String, dynamic>?;
    final sender = notification['sender'] as Map<String, dynamic>?;
    final createdAt = notification['createdAt']?.toString() ?? '';
    final communityName = community?['name']?.toString();
    final senderName = sender?['username']?.toString();
    final colors = _colorsForType(notifType);
    final title = _titleForType(notifType, senderName);

    return Dismissible(
      key: ValueKey(notification['id'].toString()),
      direction: isRead ? DismissDirection.none : DismissDirection.endToStart,
      onDismissed: (_) => onMarkRead(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.done_all_rounded, color: colors.primary),
      ),
      child: GestureDetector(
        onTap: () => _onTap(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            color: isRead ? null : colors.primary.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRead
                  ? DesignTokens.border.withValues(alpha: 0.5)
                  : colors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconForType(notifType),
                    color: colors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                        color: isRead
                            ? DesignTokens.textSecondary
                            : DesignTokens.textPrimary,
                      ),
                    ),
                    if (bodyPreview.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        bodyPreview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: isRead
                              ? DesignTokens.textTertiary
                              : DesignTokens.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (communityName != null) ...[
                          Text(
                            'y/$communityName',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: DesignTokens.textTertiary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          _timeAgo(createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: DesignTokens.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _titleForType(String type, String? sender) {
    final who = sender != null ? 'u/$sender' : 'Someone';
    switch (type) {
      case 'post_reply':
        return '$who replied to your post';
      case 'comment_reply':
        return '$who replied to your comment';
      case 'post_mention':
        return '$who mentioned you in a post';
      case 'comment_mention':
        return '$who mentioned you in a comment';
      case 'upvote_milestone':
        return 'Upvote milestone reached!';
      case 'award':
        return '$who gave you an award';
      case 'mod_action':
        return 'Mod action taken';
      case 'modmail':
        return 'New modmail message';
      case 'community_invite':
        return 'Community invite';
      default:
        return 'Notification';
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'post_reply':
        return Icons.reply_rounded;
      case 'comment_reply':
        return Icons.reply_all_rounded;
      case 'post_mention':
      case 'comment_mention':
        return Icons.alternate_email_rounded;
      case 'upvote_milestone':
        return Icons.trending_up_rounded;
      case 'award':
        return Icons.auto_awesome_rounded;
      case 'mod_action':
        return Icons.shield_rounded;
      case 'modmail':
        return Icons.mail_outline_rounded;
      case 'community_invite':
        return Icons.group_add_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  ({Color primary, Color light}) _colorsForType(String type) {
    switch (type) {
      case 'post_reply':
      case 'comment_reply':
        return (
          primary: const Color(0xFF389E75),
          light: const Color(0xFFE8F5E9)
        );
      case 'post_mention':
      case 'comment_mention':
        return (
          primary: const Color(0xFF5A6BB2),
          light: const Color(0xFFEDE7F6)
        );
      case 'upvote_milestone':
        return (
          primary: const Color(0xFFE87E5E),
          light: const Color(0xFFFFF3E0)
        );
      case 'award':
        return (
          primary: const Color(0xFFE5B300),
          light: const Color(0xFFFFF8E1)
        );
      case 'mod_action':
        return (
          primary: const Color(0xFFE53E3E),
          light: const Color(0xFFFFEBEE)
        );
      case 'modmail':
        return (
          primary: const Color(0xFF6B48FF),
          light: const Color(0xFFF3E5F5)
        );
      case 'community_invite':
        return (
          primary: const Color(0xFF389E75),
          light: const Color(0xFFE8F5E9)
        );
      default:
        return (primary: DesignTokens.primary, light: const Color(0xFFE3F2FD));
    }
  }

  String _timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${diff.inDays ~/ 7}w ago';
    } catch (_) {
      return '';
    }
  }
}
