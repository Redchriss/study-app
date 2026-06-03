import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';
import 'settings_widgets.dart';
import 'settings_dialogs.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _searchCtrl = TextEditingController();
  List<SettingsItem> _allItems = [];
  List<SettingsItem> _filteredItems = [];
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

  List<SettingsItem> _buildItems() {
    return [
      SettingsItem('Account', Icons.person_outline, [
        SettingsSub(Icons.edit_outlined, 'Edit Profile', '/edit-profile'),
        SettingsSub(Icons.auto_awesome_outlined, 'Plans & Credits', '/upgrade'),
        SettingsSub(Icons.emoji_events_outlined, 'Leaderboard', '/leaderboard'),
      ]),
      SettingsItem('Preferences', Icons.tune_outlined, [
        SettingsSub(Icons.history_outlined, 'Study History', '/history'),
        SettingsSub(Icons.bookmark_outline, 'Bookmarks', '/bookmarks'),
        SettingsSub(Icons.article_outlined, 'Past Papers', '/past-papers'),
        SettingsSub(
            Icons.library_books_outlined, 'Paper Library', '/paper-library'),
        SettingsSub(
            Icons.upload_file_outlined, 'Upload Material', '/upload-material'),
        SettingsSub(Icons.folder_special_outlined, 'My Uploads', '/my-uploads'),
      ]),
      SettingsItem('Community', Icons.groups_outlined, [
        SettingsSub(
            Icons.notifications_outlined, 'Notifications', '/home/inbox'),
      ]),
      SettingsItem('Appearance', Icons.palette_outlined, [
        SettingsSub(Icons.brightness_auto_outlined, 'Theme', null,
            isTheme: true),
      ]),
      SettingsItem('Support', Icons.help_outline, [
        SettingsSub(Icons.info_outline, 'About', '/about'),
        SettingsSub(
            Icons.description_outlined, 'Terms of Service', '/legal/terms'),
        SettingsSub(
            Icons.privacy_tip_outlined, 'Privacy Policy', '/legal/privacy'),
        SettingsSub(Icons.help_outline, 'FAQ', '/legal/faq'),
        SettingsSub(Icons.support_agent_outlined, 'Support', '/legal/support'),
      ]),
      SettingsItem('Danger Zone', Icons.warning_amber_outlined, [
        SettingsSub(Icons.logout, 'Log Out', null, isDanger: true),
        SettingsSub(Icons.delete_forever_outlined, 'Delete Account', null,
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
              return SettingsItem(section.title, section.icon, subs);
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
            SettingsSectionHeader(title: section.title),
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

  Widget _buildItem(BuildContext context, SettingsSub item, bool dark) {
    if (item.isTheme) {
      return SettingsThemeSelector(dark: dark);
    }
    if (item.isDanger) {
      return SettingsDangerRow(
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
        builder: (ctx) => LogoutDialog(
          onLogout: () => ref.read(authProvider.notifier).logout(),
        ),
      );
    } else if (label == 'Delete Account') {
      showDialog(
        context: context,
        builder: (ctx) => DeleteAccountDialog(
          onDelete: (password) {
            Navigator.pop(ctx);
            _performDeleteAccount(password);
          },
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
        builder: (ctx) => DeleteAccountErrorDialog(error: error),
      );
    }
  }
}
