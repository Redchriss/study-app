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

class ProfilePreferencesSection extends ConsumerWidget {
  const ProfilePreferencesSection({super.key});

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
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (themeMode == ThemeMode.dark
                            ? DesignTokens.warning
                            : DesignTokens.primary)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                  child: Icon(
                    themeMode == ThemeMode.dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    size: 18,
                    color: themeMode == ThemeMode.dark
                        ? DesignTokens.warning
                        : DesignTokens.primary,
                  ),
                ),
                title: Text(
                    themeMode == ThemeMode.dark ? 'Light Mode' : 'Dark Mode',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                trailing: const Icon(Icons.chevron_right,
                    size: 18, color: DesignTokens.textTertiary),
                onTap: () {
                  final current = ref.read(themeModeProvider);
                  final next = current == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;
                  ref.read(themeModeProvider.notifier).state = next;
                  SharedPreferences.getInstance().then((p) => p.setString(
                      'theme_mode', next == ThemeMode.dark ? 'dark' : 'light'));
                },
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                visualDensity: VisualDensity.compact,
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
