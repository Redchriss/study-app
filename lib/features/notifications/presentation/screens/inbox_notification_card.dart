import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';
import 'inbox_notification_card_helpers.dart';

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
    final colors = notificationColorsForType(notifType);
    final title = notificationTitleForType(notifType, senderName);

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
                child: Icon(notificationIconForType(notifType),
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
                          notificationTimeAgo(createdAt),
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
}
