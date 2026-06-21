import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import 'upload_material_manager.dart';
import 'upload_step_type.dart';

class UploadStepReview extends StatelessWidget {
  final UploadMaterialManager manager;

  const UploadStepReview({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final typeInfo = kUploadTypes
        .where((t) => t.$1 == manager.contentType)
        .firstOrNull;
    final typeIcon = typeInfo?.$4 ?? Icons.description_rounded;
    final typeColor = typeInfo?.$5 ?? DesignTokens.primary;
    final typeLabel = typeInfo?.$2 ?? manager.contentType;
    final subjectName = _findSubjectName();
    final title = manager.titleCtrl.text.trim();
    final description = manager.descCtrl.text.trim();
    final hasFile = manager.selectedFile != null;
    final hasYoutube = manager.youtubeCtrl.text.trim().isNotEmpty;
    final hasText = manager.textCtrl.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review & submit',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Double-check everything looks right before submitting.',
              style: TextStyle(
                  color: DesignTokens.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              border: Border.all(
                  color: (dark ? DesignTokens.darkBorder : DesignTokens.border)
                      .withValues(alpha: 0.5)),
              boxShadow: DesignTokens.shadowSm(dark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(typeIcon, color: typeColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(typeLabel,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                          if (subjectName != null)
                            Text(subjectName,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: DesignTokens.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _MetaRow(label: 'Title', value: title),
                if (description.isNotEmpty)
                  _MetaRow(label: 'Description', value: description, maxLines: 3),
                if (hasFile)
                  _MetaRow(
                      label: 'File',
                      value:
                          '${manager.selectedFile!.name} (${_formatSize(manager.selectedFile!.size)})'),
                if (hasYoutube)
                  _MetaRow(label: 'YouTube', value: manager.youtubeCtrl.text.trim()),
                if (hasText)
                  _MetaRow(
                      label: 'Notes',
                      value:
                          '${manager.textCtrl.text.trim().length} characters pasted'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ChecklistItem(
            icon: title.isNotEmpty ? Icons.check_circle : Icons.error_outline,
            color: title.isNotEmpty ? DesignTokens.success : DesignTokens.error,
            text: title.isNotEmpty ? 'Title added' : 'Add a title',
          ),
          _ChecklistItem(
            icon: subjectName != null
                ? Icons.check_circle
                : Icons.error_outline,
            color: subjectName != null
                ? DesignTokens.success
                : DesignTokens.error,
            text: subjectName != null
                ? 'Subject selected'
                : 'Select a subject',
          ),
          _ChecklistItem(
            icon: _hasContent
                ? Icons.check_circle
                : Icons.error_outline,
            color: _hasContent ? DesignTokens.success : DesignTokens.error,
            text: _hasContent ? 'Content ready' : 'Add content (file, URL, or text)',
          ),
        ],
      ),
    );
  }

  bool get _hasContent {
    if (manager.requiresFile) return manager.selectedFile != null;
    if (manager.contentType == 'video') return manager.youtubeCtrl.text.trim().isNotEmpty;
    if (manager.contentType == 'text') {
      return manager.textCtrl.text.trim().isNotEmpty ||
          manager.selectedFile != null;
    }
    return manager.selectedFile != null;
  }

  String? _findSubjectName() {
    if (manager.subjectId == null || manager.subjects == null) return null;
    for (final s in manager.subjects!) {
      if (s['id']?.toString() == manager.subjectId) {
        return s['name']?.toString();
      }
    }
    return null;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  final int maxLines;

  const _MetaRow({
    required this.label,
    required this.value,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textTertiary)),
          ),
          Expanded(
            child: Text(value,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _ChecklistItem({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}
