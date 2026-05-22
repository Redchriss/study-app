import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import 'edit_profile_manager.dart';
import 'edit_profile_widgets.dart';

class SchoolSection extends StatelessWidget {
  final EditProfileManager m;
  final String level;
  final bool dark;
  const SchoolSection(
      {super.key, required this.m, required this.level, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: dark ? DesignTokens.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: DesignTokens.shadowSm(dark)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
                color: dark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Your level',
                  style: TextStyle(
                      fontSize: 12,
                      color: DesignTokens.textSecondary,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                  level == 'primary'
                      ? 'Primary'
                      : level == 'secondary'
                          ? 'Secondary'
                          : 'University / college',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
            ]),
          ),
          const SizedBox(height: 16),
          if (level == 'primary') _PrimaryFields(m: m, dark: dark),
          if (level == 'secondary') _SecondaryFields(m: m, dark: dark),
          if (level == 'tertiary') _TertiaryFields(m: m, dark: dark),
        ],
      ),
    );
  }
}

class _PrimaryFields extends StatelessWidget {
  final EditProfileManager m;
  final bool dark;
  const _PrimaryFields({required this.m, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ModernDropdown<int>(
          dropKey: ValueKey('std_${m.standard ?? 0}'),
          label: 'Standard',
          value: m.standard,
          items: List.generate(
              8,
              (i) => DropdownMenuItem(
                  value: i + 1, child: Text('Standard ${i + 1}'))),
          onChanged: (v) => m.updateState(() => m.standard = v),
          dark: dark),
      const SizedBox(height: 16),
      ModernDropdown<String>(
          dropKey: ValueKey('term_${m.term ?? 'x'}'),
          label: 'Term',
          value: m.term != null && ['1', '2', '3'].contains(m.term)
              ? m.term
              : null,
          items: const [
            DropdownMenuItem(value: '1', child: Text('Term 1')),
            DropdownMenuItem(value: '2', child: Text('Term 2')),
            DropdownMenuItem(value: '3', child: Text('Term 3'))
          ],
          onChanged: (v) => m.updateState(() => m.term = v),
          dark: dark),
      const SizedBox(height: 16),
      ModernListTile(
          title: 'Primary school',
          subtitle: m.primarySchoolName ?? 'Not set \u2014 tap to search',
          icon: Icons.school_rounded,
          dark: dark,
          onTap: () => m.openSchoolPicker(true)),
    ]);
  }
}

class _SecondaryFields extends StatelessWidget {
  final EditProfileManager m;
  final bool dark;
  const _SecondaryFields({required this.m, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ModernDropdown<int>(
          dropKey: ValueKey('form_${m.form ?? 0}'),
          label: 'Form',
          value: m.form,
          items: List.generate(
              4,
              (i) =>
                  DropdownMenuItem(value: i + 1, child: Text('Form ${i + 1}'))),
          onChanged: (v) => m.updateState(() => m.form = v),
          dark: dark),
      const SizedBox(height: 16),
      ModernDropdown<String>(
          dropKey: ValueKey('term_${m.term ?? 'x'}'),
          label: 'Term',
          value: m.term != null && ['1', '2', '3'].contains(m.term)
              ? m.term
              : null,
          items: const [
            DropdownMenuItem(value: '1', child: Text('Term 1')),
            DropdownMenuItem(value: '2', child: Text('Term 2')),
            DropdownMenuItem(value: '3', child: Text('Term 3'))
          ],
          onChanged: (v) => m.updateState(() => m.term = v),
          dark: dark),
      const SizedBox(height: 16),
      ModernListTile(
          title: 'Secondary school',
          subtitle: m.secondarySchoolName ?? 'Not set \u2014 tap to search',
          icon: Icons.school_rounded,
          dark: dark,
          onTap: () => m.openSchoolPicker(false)),
    ]);
  }
}

class _TertiaryFields extends StatelessWidget {
  final EditProfileManager m;
  final bool dark;
  const _TertiaryFields({required this.m, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ModernListTile(
          title: 'Institution',
          subtitle: m.universityName ?? 'Not set \u2014 tap to search',
          icon: Icons.account_balance_rounded,
          dark: dark,
          onTap: m.openUniversityPicker),
      const SizedBox(height: 16),
      ModernListTile(
          title: 'Programme',
          subtitle: m.programName ?? 'Not set \u2014 tap to choose',
          icon: Icons.menu_book_rounded,
          dark: dark,
          onTap: m.openProgramPicker),
    ]);
  }
}
