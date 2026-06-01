import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/design_tokens.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  bool _pushEnabled = true;
  bool _soundEnabled = true;
  bool _postReply = true;
  bool _commentReply = true;
  bool _postMention = true;
  bool _upvoteMilestone = false;
  bool _award = true;
  bool _modAction = true;
  bool _modmail = true;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification preferences',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SectionHeader(title: 'Push & Sound'),
          const SizedBox(height: 8),
          _buildSwitchTile(
            dark: dark,
            icon: Icons.notifications_active_rounded,
            title: 'Push notifications',
            subtitle: 'Receive push notifications on your device',
            value: _pushEnabled,
            onChanged: (v) => setState(() => _pushEnabled = v),
          ),
          _buildSwitchTile(
            dark: dark,
            icon: Icons.volume_up_rounded,
            title: 'Sound',
            subtitle: 'Play a sound when receiving notifications',
            value: _soundEnabled,
            onChanged: (v) => setState(() => _soundEnabled = v),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Notification Types'),
          const SizedBox(height: 8),
          _buildSwitchTile(
            dark: dark,
            icon: Icons.reply_rounded,
            title: 'Post replies',
            subtitle: 'Someone replies to your post',
            value: _postReply,
            onChanged: (v) => setState(() => _postReply = v),
          ),
          _buildSwitchTile(
            dark: dark,
            icon: Icons.reply_all_rounded,
            title: 'Comment replies',
            subtitle: 'Someone replies to your comment',
            value: _commentReply,
            onChanged: (v) => setState(() => _commentReply = v),
          ),
          _buildSwitchTile(
            dark: dark,
            icon: Icons.alternate_email_rounded,
            title: 'Mentions',
            subtitle: 'Someone mentions you with u/username',
            value: _postMention,
            onChanged: (v) => setState(() => _postMention = v),
          ),
          _buildSwitchTile(
            dark: dark,
            icon: Icons.trending_up_rounded,
            title: 'Upvote milestones',
            subtitle: 'Your post reaches 10, 100, or 1000 upvotes',
            value: _upvoteMilestone,
            onChanged: (v) => setState(() => _upvoteMilestone = v),
          ),
          _buildSwitchTile(
            dark: dark,
            icon: Icons.auto_awesome_rounded,
            title: 'Awards',
            subtitle: 'Someone gives you an award',
            value: _award,
            onChanged: (v) => setState(() => _award = v),
          ),
          _buildSwitchTile(
            dark: dark,
            icon: Icons.shield_rounded,
            title: 'Mod actions',
            subtitle: 'Your content is removed or you are banned',
            value: _modAction,
            onChanged: (v) => setState(() => _modAction = v),
          ),
          _buildSwitchTile(
            dark: dark,
            icon: Icons.mail_outline_rounded,
            title: 'Modmail',
            subtitle: 'New messages to the moderation team',
            value: _modmail,
            onChanged: (v) => setState(() => _modmail = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required bool dark,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
      decoration: BoxDecoration(
        color: dark ? DesignTokens.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DesignTokens.border.withValues(alpha: 0.5)),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: DesignTokens.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: DesignTokens.primary, size: 18),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        contentPadding: EdgeInsets.zero,
        dense: true,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: DesignTokens.textSecondary)),
    );
  }
}
