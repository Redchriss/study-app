import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import 'upload_material_manager.dart';

class UploadStepSubject extends StatelessWidget {
  final UploadMaterialManager manager;
  final ValueChanged<String?> onSubjectChanged;

  const UploadStepSubject({
    super.key,
    required this.manager,
    required this.onSubjectChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isTertiary = manager.educationLevel == 'tertiary';
    final isPrimary = manager.educationLevel == 'primary';
    final isSecondary = manager.educationLevel == 'secondary';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pick a subject',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(_subtitle(),
              style: const TextStyle(
                  color: DesignTokens.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          if (isPrimary || isSecondary)
            _LevelBadge(manager: manager, dark: dark),
          if (isPrimary || isSecondary) const SizedBox(height: 12),
          if (isTertiary && manager.profileProgramName != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DesignTokens.primary.withValues(alpha: dark ? 0.15 : 0.06),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                border: Border.all(
                    color: DesignTokens.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.school_rounded,
                      size: 18, color: DesignTokens.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(manager.profileUniversityName ?? 'University',
                            style: TextStyle(
                                fontSize: 11,
                                color: DesignTokens.textSecondary)),
                        Text(manager.profileProgramName!,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (manager.loadingSubjects)
            const ShimmerBox(height: 56, radius: DesignTokens.radiusMd)
          else if (manager.subjectLoadError != null)
            ErrorState(
              message: manager.subjectLoadError!,
              onRetry: () => manager.loadSubjects(
                  programId: manager.profileProgramId),
              actionLabel: 'Complete Profile',
              onAction: () =>
                  Navigator.of(context).pushReplacementNamed('/edit-profile'),
            )
          else if (manager.subjects == null || manager.subjects!.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DesignTokens.warning.withValues(alpha: dark ? 0.15 : 0.06),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                border: Border.all(
                    color: DesignTokens.warning.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 20, color: DesignTokens.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isTertiary
                          ? 'No subjects found for your program. Contact support if this seems wrong.'
                          : 'No subjects available for your level yet.',
                      style: const TextStyle(
                          fontSize: 13, color: DesignTokens.textSecondary),
                    ),
                  ),
                ],
              ),
            )
          else
            DropdownButtonFormField<String>(
              key: ValueKey(
                  'subject_${manager.subjects?.length}_${manager.subjectId}'),
              value: manager.subjectId,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
              items: (manager.subjects ?? [])
                  .map((s) => DropdownMenuItem<String>(
                        value: s['id']?.toString(),
                        child: Text(s['name']?.toString() ?? ''),
                      ))
                  .toList(),
              onChanged: onSubjectChanged,
            ),
        ],
      ),
    );
  }

  String _subtitle() {
    if (manager.educationLevel == 'primary') {
      return 'Subjects are filtered to Standard ${manager.profileStandard ?? '?'}. Update your profile if this is wrong.';
    }
    if (manager.educationLevel == 'secondary') {
      return 'Subjects are filtered to Form ${manager.profileForm ?? '?'}. Update your profile if this is wrong.';
    }
    if (manager.educationLevel == 'tertiary') {
      return manager.profileProgramName != null
          ? 'Showing subjects for your program.'
          : 'Complete your profile with a university and program to see matching subjects.';
    }
    return 'Select the subject this material covers.';
  }
}

class _LevelBadge extends StatelessWidget {
  final UploadMaterialManager manager;
  final bool dark;
  const _LevelBadge({required this.manager, required this.dark});

  @override
  Widget build(BuildContext context) {
    final isPrimary = manager.educationLevel == 'primary';
    final label = isPrimary
        ? 'Standard ${manager.profileStandard ?? '?'}'
        : 'Form ${manager.profileForm ?? '?'}';
    final color = isPrimary ? DesignTokens.accent : DesignTokens.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
              isPrimary ? Icons.child_care_rounded : Icons.school_rounded,
              size: 14,
              color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}
