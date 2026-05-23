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
    final body = notification['bodyPreview']?.toString() ?? '';
    final community = notification['community'] as Map<String, dynamic>?;
    final createdAt = notification['createdAt']?.toString() ?? '';

    return Dismissible(
      key: ValueKey(notification['id'].toString()),
      direction: isRead ? DismissDirection.none : DismissDirection.endToStart,
      onDismissed: (_) => onMarkRead(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: DesignTokens.primary,
        child: const Icon(Icons.done_all_rounded, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () => _onTap(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isRead ? null : DesignTokens.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: isRead ? Border.all(color: DesignTokens.border) : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _colorForType(notifType).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconForType(notifType),
                    color: _colorForType(notifType), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isRead ? FontWeight.w500 : FontWeight.w700,
                          color: isRead
                              ? DesignTokens.textSecondary
                              : DesignTokens.textPrimary,
                        )),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (community != null) ...[
                          Text('y/${community['name']}',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: DesignTokens.primary)),
                          const SizedBox(width: 8),
                        ],
                        Text(_timeAgo(createdAt),
                            style: TextStyle(
                                fontSize: 11,
                                color: DesignTokens.textTertiary)),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                      color: _colorForType(notifType), shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'post_reply':
        return Icons.reply_rounded;
      case 'comment_reply':
        return Icons.reply_all_rounded;
      case 'post_mention':
        return Icons.alternate_email_rounded;
      case 'comment_mention':
        return Icons.alternate_email_rounded;
      case 'upvote_milestone':
        return Icons.arrow_upward_rounded;
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

  Color _colorForType(String type) {
    switch (type) {
      case 'post_reply':
        return const Color(0xFF389E75);
      case 'comment_reply':
        return const Color(0xFF389E75);
      case 'post_mention':
        return const Color(0xFF5A6BB2);
      case 'comment_mention':
        return const Color(0xFF5A6BB2);
      case 'upvote_milestone':
        return const Color(0xFFE87E5E);
      case 'award':
        return const Color(0xFFE5B300);
      case 'mod_action':
        return const Color(0xFFE53E3E);
      case 'modmail':
        return const Color(0xFF6B48FF);
      case 'community_invite':
        return const Color(0xFF389E75);
      default:
        return DesignTokens.primary;
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
