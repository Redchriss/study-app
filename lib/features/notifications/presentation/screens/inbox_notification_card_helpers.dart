import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

String notificationTitleForType(String type, String? sender) {
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

IconData notificationIconForType(String type) {
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

({Color primary, Color light}) notificationColorsForType(String type) {
  switch (type) {
    case 'post_reply':
    case 'comment_reply':
      return (primary: const Color(0xFF389E75), light: const Color(0xFFE8F5E9));
    case 'post_mention':
    case 'comment_mention':
      return (primary: const Color(0xFF5A6BB2), light: const Color(0xFFEDE7F6));
    case 'upvote_milestone':
      return (primary: const Color(0xFFE87E5E), light: const Color(0xFFFFF3E0));
    case 'award':
      return (primary: const Color(0xFFE5B300), light: const Color(0xFFFFF8E1));
    case 'mod_action':
      return (primary: const Color(0xFFE53E3E), light: const Color(0xFFFFEBEE));
    case 'modmail':
      return (primary: const Color(0xFF6B48FF), light: const Color(0xFFF3E5F5));
    case 'community_invite':
      return (primary: const Color(0xFF389E75), light: const Color(0xFFE8F5E9));
    default:
      return (primary: DesignTokens.primary, light: const Color(0xFFE3F2FD));
  }
}

String notificationTimeAgo(String iso) {
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
