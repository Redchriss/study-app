import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(context, Icons.person_outline, 'Edit Profile', '/edit-profile'),
          _card(context, Icons.notifications_outlined, 'Notifications', null),
          _card(context, Icons.palette_outlined, 'Theme', null,
              trailing: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('System',
                    style: TextStyle(color: DesignTokens.textSecondary)),
                SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded,
                    color: DesignTokens.textTertiary),
              ])),
          const Divider(height: 32),
          _card(context, Icons.info_outline, 'About', '/about'),
          _card(context, Icons.description_outlined, 'Terms of Service',
              '/legal/terms'),
          _card(context, Icons.privacy_tip_outlined, 'Privacy Policy',
              '/legal/privacy'),
          _card(context, Icons.help_outline, 'FAQ', '/legal/faq'),
          _card(context, Icons.support_agent_outlined, 'Support',
              '/legal/support'),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, IconData icon, String label, String? route,
      {Widget? trailing}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: DesignTokens.primary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: trailing ??
            const Icon(Icons.chevron_right_rounded,
                color: DesignTokens.textTertiary),
        onTap: route != null ? () => context.push(route) : null,
      ),
    );
  }
}
