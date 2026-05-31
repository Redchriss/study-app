import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/app_preferences_service.dart';
import '../../../../core/services/retention_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../main.dart';
import 'profile_list_widgets.dart';
import 'profile_preference_switch.dart';

final _themeLabel = <ThemeMode, String>{
  ThemeMode.system: 'System',
  ThemeMode.light: 'Light',
  ThemeMode.dark: 'Dark',
};

final _themeIcon = <ThemeMode, IconData>{
  ThemeMode.system: Icons.brightness_auto_outlined,
  ThemeMode.light: Icons.light_mode_outlined,
  ThemeMode.dark: Icons.dark_mode_outlined,
};

class ProfilePreferencesSection extends ConsumerWidget {
  const ProfilePreferencesSection({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = AppPreferencesService();
    final themeMode = ref.watch(themeModeProvider);
    return Column(
      children: [
        const SectionLabel(label: 'PREFERENCES'),
        const SizedBox(height: 10),
        GlassCard(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: DesignTokens.info.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusSm),
                      ),
                      child: Icon(_themeIcon[themeMode],
                          size: 16, color: DesignTokens.info),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Appearance',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                    Text(_themeLabel[themeMode] ?? 'System',
                        style: const TextStyle(
                            fontSize: 13, color: DesignTokens.textSecondary)),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
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
                ),
              ),
              const SectionDivider(),
              AsyncPreferenceSwitch(
                icon: Icons.data_saver_on_outlined,
                iconColor: DesignTokens.accent,
                loadValue: preferences.isLowDataMode,
                onChanged: (value) async {
                  await preferences.setLowDataMode(value);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(value
                              ? 'Low-data mode enabled.'
                              : 'Low-data mode disabled.')),
                    );
                  }
                },
                title: 'Low-data Mode',
                subtitle: 'Reduces heavy previews on slow networks.',
              ),
              const SectionDivider(),
              AsyncPreferenceSwitch(
                icon: Icons.notifications_outlined,
                iconColor: DesignTokens.secondary,
                loadValue: preferences.studyRemindersEnabled,
                onChanged: (value) async {
                  await preferences.setStudyRemindersEnabled(value);
                  await RetentionService().refreshStudyReminder();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(value
                              ? 'Study reminders on.'
                              : 'Study reminders off.')),
                    );
                  }
                },
                title: 'Study Reminders',
                subtitle: 'Daily nudge to keep your streak alive.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
