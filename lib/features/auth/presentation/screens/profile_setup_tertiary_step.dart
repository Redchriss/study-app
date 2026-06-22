import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import 'profile_selection_field.dart';

const _kTertiaryColor = Color(0xFF5A6BB2);

class ProfileUniversityStep extends StatelessWidget {
  final String? universityName;
  final String? universityId;
  final VoidCallback onPickUniversity;
  final VoidCallback onContinue;

  const ProfileUniversityStep({
    super.key,
    this.universityName,
    this.universityId,
    required this.onPickUniversity,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Institution', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Search public and private colleges and universities '
          '(same sheet as Edit profile).',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: DesignTokens.textSecondary),
        ),
        const SizedBox(height: 20),
        ProfileSelectionField(
          icon: Icons.account_balance_rounded,
          label: 'Institution',
          placeholder: 'Tap to choose your institution',
          value: universityName,
          color: _kTertiaryColor,
          onTap: onPickUniversity,
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: universityId == null ? null : onContinue,
          child: const Text('Continue to programme'),
        ),
      ],
    );
  }
}

class ProfileProgramStep extends StatelessWidget {
  final String? universityId;
  final String? universityName;
  final String? programName;
  final String? programId;
  final bool saving;
  final VoidCallback onPickProgram;
  final VoidCallback onFinish;
  final VoidCallback onBack;

  const ProfileProgramStep({
    super.key,
    this.universityId,
    this.universityName,
    this.programName,
    this.programId,
    required this.saving,
    required this.onPickProgram,
    required this.onFinish,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    if (universityId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Select an institution first'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onBack,
              child: const Text('Back'),
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Your programme', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (universityName != null)
          Text(
            'Institution: $universityName',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: DesignTokens.textSecondary),
          ),
        const SizedBox(height: 16),
        ProfileSelectionField(
          icon: Icons.menu_book_rounded,
          label: 'Programme',
          placeholder: 'Tap to choose your programme',
          value: programName,
          color: _kTertiaryColor,
          onTap: onPickProgram,
        ),
        const SizedBox(height: 12),
        Text(
          'Choose your programme, then finish setup.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: DesignTokens.textSecondary),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: (programId == null || saving) ? null : onFinish,
          child: saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Finish setup'),
        ),
      ],
    );
  }
}
