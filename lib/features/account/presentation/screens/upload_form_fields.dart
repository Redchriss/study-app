import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import 'upload_material_labels.dart';
import 'upload_material_manager.dart';

class UploadFormFields extends StatelessWidget {
  const UploadFormFields({
    super.key,
    required this.manager,
    required this.onSubjectChanged,
  });

  final UploadMaterialManager manager;
  final ValueChanged<String?> onSubjectChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          TextField(
            controller: manager.titleCtrl,
            decoration: InputDecoration(
              labelText: 'Title',
              hintText: UploadMaterialLabels.titlePlaceholder(
                  manager.contentType, manager.educationLevel),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: DesignTokens.spMd),
          if (manager.loadingSubjects)
            const ShimmerBox(height: 56, radius: DesignTokens.radiusMd)
          else if (manager.subjectLoadError != null)
            ErrorState(
              message: manager.subjectLoadError!,
              onRetry: manager.loadSubjects,
              actionLabel: 'Complete Profile',
              onAction: () => context.go('/edit-profile'),
            )
          else
            DropdownButtonFormField<String>(
              key: ValueKey(
                  'subject_${manager.subjects?.length}_${manager.subjectId}'),
              initialValue: manager.subjectId,
              decoration: const InputDecoration(labelText: 'Subject'),
              items: (manager.subjects ?? [])
                  .map((s) => DropdownMenuItem<String>(
                        value: s['id']?.toString(),
                        child: Text(s['name']?.toString() ?? ''),
                      ))
                  .toList(),
              onChanged: onSubjectChanged,
            ),
          const SizedBox(height: DesignTokens.spMd),
          TextField(
            controller: manager.descCtrl,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText:
                  UploadMaterialLabels.descPlaceholder(manager.educationLevel),
            ),
            maxLines: 3,
            textInputAction: TextInputAction.next,
          ),
        ],
      ),
    );
  }
}
