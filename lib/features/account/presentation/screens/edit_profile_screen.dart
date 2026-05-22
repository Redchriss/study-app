import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'edit_profile_manager.dart';
import 'edit_profile_school_section.dart';
import 'edit_profile_widgets.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _manager = EditProfileManager();

  @override
  void initState() {
    super.initState();
    _manager.attach(ref: ref, context: context, setState: (fn) => setState(fn));
    final user = ref.read(authProvider).user;
    _manager.initFromUser(user);
  }

  @override
  void dispose() {
    _manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final m = _manager;
    final user = ref.watch(authProvider).user;
    final prof = user?['profile'];
    final level = m.educationLevel ??
        (prof is Map<String, dynamic>
            ? prof['educationLevel'] as String?
            : null);

    return Scaffold(
      appBar: AppBar(
          title: Text('Edit profile', style: theme.textTheme.titleLarge)),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.spLg),
        children: [
          Avatar(user: user, dark: dark),
          const SizedBox(height: 32),
          Text('Personal details',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          PersonalDetails(m: m, dark: dark),
          const SizedBox(height: 32),
          Text('School & studies',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            'Search universities (public/private), pick a programme, or set your school \u2014 same as setup. Kids: Profile \u2192 Kids mode.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: DesignTokens.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (level == null || level.isEmpty)
            const NoLevelWarning()
          else
            SchoolSection(m: m, level: level, dark: dark),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: m.saving ? null : () => m.save(),
              style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
              child: m.saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save changes',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
