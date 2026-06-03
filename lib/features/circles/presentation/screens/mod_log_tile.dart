import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';

class ModLogTile extends StatelessWidget {
  final Map<String, dynamic> entry;

  const ModLogTile({super.key, required this.entry});

  IconData _iconForAction(String action) {
    switch (action) {
      case 'remove_post':
        return Icons.delete_outline;
      case 'remove_comment':
        return Icons.delete_sweep_outlined;
      case 'ban_user':
        return Icons.block;
      case 'unban_user':
        return Icons.person_add_alt;
      case 'mute_user':
        return Icons.volume_off_outlined;
      case 'unmute_user':
        return Icons.volume_up_outlined;
      case 'approve_post':
        return Icons.check_circle_outline;
      case 'pin_post':
        return Icons.push_pin_outlined;
      case 'lock_post':
        return Icons.lock_outline;
      case 'edit_settings':
        return Icons.settings_outlined;
      case 'add_mod':
        return Icons.admin_panel_settings_outlined;
      case 'remove_mod':
        return Icons.remove_moderator_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _colorForAction(String action) {
    switch (action) {
      case 'remove_post':
      case 'remove_comment':
      case 'ban_user':
        return DesignTokens.error;
      case 'unban_user':
      case 'unmute_user':
      case 'approve_post':
        return DesignTokens.success;
      case 'pin_post':
        return DesignTokens.warning;
      case 'lock_post':
        return DesignTokens.textSecondary;
      case 'mute_user':
        return DesignTokens.warning;
      case 'add_mod':
        return DesignTokens.primary;
      case 'remove_mod':
        return DesignTokens.error;
      default:
        return DesignTokens.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = entry['action'] as String? ?? '';
    final moderator = entry['moderator'] as Map<String, dynamic>?;
    final targetUser = entry['targetUser'] as Map<String, dynamic>?;
    final post = entry['post'] as Map<String, dynamic>?;
    final createdAt = entry['createdAt'] as String? ?? '';

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _colorForAction(action).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(_iconForAction(action),
            size: 18, color: _colorForAction(action)),
      ),
      title: Text(
        action.replaceAll('_', ' '),
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          'by u/${moderator?['username'] ?? 'unknown'}',
          if (targetUser != null) '→ u/${targetUser['username']}',
          if (post != null) 'on "${post['title']}"',
        ].join(' '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(createdAt),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: DesignTokens.textTertiary),
          ),
        ],
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${diff.inDays ~/ 7}w ago';
    } catch (_) {
      return '';
    }
  }
}
