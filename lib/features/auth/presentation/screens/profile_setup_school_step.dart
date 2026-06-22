import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import 'profile_selection_field.dart';

class ProfileSchoolStep extends StatelessWidget {
  final bool isPrimary;
  final String? schoolName;
  final String? schoolId;
  final VoidCallback onPickSchool;
  final VoidCallback onSkip;
  final VoidCallback onContinue;

  const ProfileSchoolStep({
    super.key,
    required this.isPrimary,
    this.schoolName,
    this.schoolId,
    required this.onPickSchool,
    required this.onSkip,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          isPrimary ? 'Your primary school' : 'Your secondary school',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          isPrimary
              ? 'Optional — helps with local circles. Same school search as Edit profile.'
              : 'Optional. Search by school name (same sheet as Edit profile).',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: DesignTokens.textSecondary),
        ),
        const SizedBox(height: 20),
        ProfileSelectionField(
          icon: Icons.school_rounded,
          label: isPrimary ? 'Primary school' : 'Secondary school',
          placeholder: 'Tap to search for your school',
          value: schoolName,
          color: isPrimary ? const Color(0xFFE87E5E) : const Color(0xFF389E75),
          onTap: onPickSchool,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: onSkip,
          child: const Text('Skip for now'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: onContinue,
          child: const Text('Continue to term'),
        ),
      ],
    );
  }
}
