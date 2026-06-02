import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/design_tokens.dart';

import '../../../../main.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _searchCtrl = TextEditingController();
  List<_SettingsItem> _allItems = [];
  List<_SettingsItem> _filteredItems = [];
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _allItems = _buildItems();
    _filteredItems = _allItems;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_SettingsItem> _buildItems() {
    return [
      _SettingsItem('Account', Icons.person_outline, [
        _SettingsSub(Icons.edit_outlined, 'Edit Profile', '/edit-profile'),
        _SettingsSub(
            Icons.auto_awesome_outlined, 'Plans & Credits', '/upgrade'),
        _SettingsSub(
            Icons.emoji_events_outlined, 'Leaderboard', '/leaderboard'),
      ]),
      _SettingsItem('Preferences', Icons.tune_outlined, [
        _SettingsSub(Icons.history_outlined, 'Study History', '/history'),
        _SettingsSub(Icons.bookmark_outline, 'Bookmarks', '/bookmarks'),
        _SettingsSub(Icons.article_outlined, 'Past Papers', '/past-papers'),
        _SettingsSub(
            Icons.library_books_outlined, 'Paper Library', '/paper-library'),
        _SettingsSub(
            Icons.upload_file_outlined, 'Upload Material', '/upload-material'),
        _SettingsSub(
            Icons.folder_special_outlined, 'My Uploads', '/my-uploads'),
      ]),
      _SettingsItem('Community', Icons.groups_outlined, [
        _SettingsSub(Icons.notifications_outlined, 'Notifications', '/circles/inbox'),
      ]),
      _SettingsItem('Appearance', Icons.palette_outlined, [
        _SettingsSub(Icons.brightness_auto_outlined, 'Theme', null,
            isTheme: true),
      ]),
      _SettingsItem('Support', Icons.help_outline, [
        _SettingsSub(Icons.info_outline, 'About', '/about'),
        _SettingsSub(
            Icons.description_outlined, 'Terms of Service', '/legal/terms'),
        _SettingsSub(
            Icons.privacy_tip_outlined, 'Privacy Policy', '/legal/privacy'),
        _SettingsSub(Icons.help_outline, 'FAQ', '/legal/faq'),
        _SettingsSub(Icons.support_agent_outlined, 'Support', '/legal/support'),
      ]),
      _SettingsItem('Danger Zone', Icons.warning_amber_outlined, [
        _SettingsSub(Icons.logout, 'Log Out', null, isDanger: true),
        _SettingsSub(Icons.delete_forever_outlined, 'Delete Account', null,
            isDanger: true),
      ]),
    ];
  }

  void _onSearch(String q) {
    setState(() {
      if (q.isEmpty) {
        _filteredItems = _allItems;
      } else {
        _filteredItems = _allItems
            .map((section) {
              final subs = section.items
                  .where((s) => s.label.toLowerCase().contains(q.toLowerCase()))
                  .toList();
              return _SettingsItem(section.title, section.icon, subs);
            })
            .where((s) => s.items.isNotEmpty)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search settings...',
                  border: InputBorder.none,
                ),
                onChanged: _onSearch,
              )
            : Text('Settings',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchCtrl.clear();
                  _filteredItems = _allItems;
                }
              });
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final section in _filteredItems) ...[
            _SectionHeader(title: section.title),
            const SizedBox(height: 8),
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg)),
              child: Column(
                children: [
                  for (int i = 0; i < section.items.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: 56),
                    _buildItem(context, section.items[i], dark),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, _SettingsSub item, bool dark) {
    if (item.isTheme) {
      return _ThemeSelector(dark: dark);
    }
    if (item.isDanger) {
      return _DangerRow(
        icon: item.icon,
        label: item.label,
        onTap: () => _handleDangerAction(item.label),
      );
    }
    return InkWell(
      onTap: item.route != null ? () => context.push(item.route!) : null,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: DesignTokens.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              ),
              child: Icon(item.icon, size: 16, color: DesignTokens.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(item.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: DesignTokens.textTertiary),
          ],
        ),
      ),
    );
  }

  void _handleDangerAction(String label) {
    if (label == 'Log Out') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusXl)),
          title: const Row(
            children: [
              Icon(Icons.logout, size: 20, color: DesignTokens.error),
              SizedBox(width: 8),
              Text('Log out?', style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          content: const Text(
              'You will need to log in again to access your study data.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(authProvider.notifier).logout();
              },
              child: const Text('Log out',
                  style: TextStyle(color: DesignTokens.error)),
            ),
          ],
        ),
      );
    } else if (label == 'Delete Account') {
      final pwdCtrl = TextEditingController();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusXl)),
          title: const Row(
            children: [
              Icon(Icons.warning_rounded, size: 20, color: DesignTokens.error),
              SizedBox(width: 8),
              Text('Delete Account',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This will permanently delete your account, '
                  'study history, progress, and all associated data. '
                  'This action cannot be undone.'),
              const SizedBox(height: 16),
              TextField(
                controller: pwdCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Enter your password to confirm',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final password = pwdCtrl.text.trim();
                if (password.isEmpty) return;
                Navigator.pop(ctx);
                _performDeleteAccount(password);
              },
              child: const Text('Delete Account',
                  style: TextStyle(color: DesignTokens.error)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _performDeleteAccount(String password) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final error = await ref.read(authProvider.notifier).deleteAccount(password);
    if (!context.mounted) return;
    Navigator.pop(context);
    if (error != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusXl)),
          title:
              const Text('Error', style: TextStyle(color: DesignTokens.error)),
          content: Text(error),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    }
  }
}

class _SettingsItem {
  final String title;
  final IconData icon;
  final List<_SettingsSub> items;
  _SettingsItem(this.title, this.icon, this.items);
}

class _SettingsSub {
  final IconData icon;
  final String label;
  final String? route;
  final bool isTheme;
  final bool isDanger;
  _SettingsSub(this.icon, this.label, this.route,
      {this.isTheme = false, this.isDanger = false});
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: title == 'DANGER ZONE'
                  ? DesignTokens.error
                  : DesignTokens.textTertiary,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _ThemeSelector extends ConsumerWidget {
  final bool dark;
  const _ThemeSelector({required this.dark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: DesignTokens.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
                child: const Icon(Icons.palette_outlined,
                    size: 16, color: DesignTokens.info),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Theme',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto_outlined, size: 16)),
              ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined, size: 16)),
              ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined, size: 16)),
            ],
            selected: {themeMode},
            onSelectionChanged: (v) => _setTheme(ref, v.first),
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  void _setTheme(WidgetRef ref, ThemeMode mode) {
    ref.read(themeModeProvider.notifier).state = mode;
    SharedPreferences.getInstance().then((p) {
      final value = switch (mode) {
        ThemeMode.dark => 'dark',
        ThemeMode.light => 'light',
        ThemeMode.system => 'system',
      };
      p.setString('theme_mode', value);
    });
  }
}

class _DangerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DangerRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: DesignTokens.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
                child: Icon(icon, size: 16, color: DesignTokens.error),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: DesignTokens.error,
                    )),
              ),
              const Icon(Icons.chevron_right,
                  size: 16, color: DesignTokens.error),
            ],
          ),
        ),
      ),
    );
  }
}
