import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class NotificationItem extends StatelessWidget {
  final Map<String, dynamic> notification;
  final bool isRead;
  final String type;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.isRead,
    required this.type,
    required this.icon,
    required this.color,
    this.onTap,
  });

  static IconData iconForType(String type) {
    switch (type) {
      case 'reply':
        return Icons.reply_rounded;
      case 'upvote':
        return Icons.arrow_upward_rounded;
      case 'circle_invite':
        return Icons.group_add_rounded;
      case 'quiz_result':
        return Icons.quiz_rounded;
      case 'ai_credits':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  static Color colorForType(String type) {
    switch (type) {
      case 'reply':
        return const Color(0xFF389E75);
      case 'upvote':
        return const Color(0xFFE87E5E);
      case 'circle_invite':
        return const Color(0xFF5A6BB2);
      case 'quiz_result':
        return const Color(0xFFE5B300);
      case 'ai_credits':
        return const Color(0xFF6B48FF);
      default:
        return DesignTokens.primary;
    }
  }

  static String timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${(diff.inDays / 7).floor()}w ago';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedPress(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dark ? DesignTokens.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:
              isRead ? null : Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: isRead
              ? null
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isRead
                    ? (dark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade100)
                    : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isRead ? DesignTokens.textTertiary : color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification['message'] ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                      color: isRead
                          ? DesignTokens.textSecondary
                          : DesignTokens.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeAgo(notification['createdAt'] as String? ?? ''),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isRead
                          ? DesignTokens.textTertiary
                          : color.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (!isRead) ...[
              const SizedBox(width: 12),
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
