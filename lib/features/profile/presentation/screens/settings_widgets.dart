import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../main.dart';

class SettingsItem {
  final String title;
  final IconData icon;
  final List<SettingsSub> items;
  SettingsItem(this.title, this.icon, this.items);
}

class SettingsSub {
  final IconData icon;
  final String label;
  final String? route;
  final bool isTheme;
  final bool isDanger;
  SettingsSub(this.icon, this.label, this.route,
      {this.isTheme = false, this.isDanger = false});
}

class SettingsSectionHeader extends StatelessWidget {
  final String title;
  const SettingsSectionHeader({super.key, required this.title});

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

class SettingsThemeSelector extends ConsumerWidget {
  final bool dark;
  const SettingsThemeSelector({super.key, required this.dark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
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
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
          ]),
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
      p.setString(
          'theme_mode',
          switch (mode) {
            ThemeMode.dark => 'dark',
            ThemeMode.light => 'light',
            ThemeMode.system => 'system',
          });
    });
  }
}

class SettingsDangerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const SettingsDangerRow(
      {super.key,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        child: Row(children: [
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
                      color: DesignTokens.error))),
          const Icon(Icons.chevron_right, size: 16, color: DesignTokens.error),
        ]),
      ),
    );
  }
}
