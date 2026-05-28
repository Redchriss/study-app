import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class TypeCard extends StatelessWidget {
  const TypeCard({
    super.key,
    required this.selected,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedPress(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 144,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? color : DesignTokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class UploadPill extends StatelessWidget {
  const UploadPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: DesignTokens.textPrimary),
      ),
    );
  }
}

class FilePickerCard extends StatelessWidget {
  const FilePickerCard({
    super.key,
    required this.fileButtonLabel,
    required this.requiresFile,
    required this.selectedFile,
    required this.onPick,
  });

  final String fileButtonLabel;
  final bool requiresFile;
  final PlatformFile? selectedFile;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedPress(
      onTap: onPick,
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: DesignTokens.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.upload_file_rounded,
                      color: DesignTokens.primary),
                ),
                const SizedBox(width: DesignTokens.spMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fileButtonLabel,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        requiresFile
                            ? 'Required for this material type.'
                            : 'Optional, but useful when you already have a file version.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: DesignTokens.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: DesignTokens.textTertiary),
              ],
            ),
            if (selectedFile != null) ...[
              const SizedBox(height: DesignTokens.spMd),
              FilePreviewCard(file: selectedFile!),
            ],
          ],
        ),
      ),
    );
  }
}

class UploadChecklist extends StatelessWidget {
  const UploadChecklist({super.key, required this.isVideo});

  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spMd),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Upload checklist',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: DesignTokens.spXs),
          const Text(
            'Keep titles specific, match the right subject, and prefer readable notes over blurry scans when possible.',
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
          if (isVideo) ...[
            const SizedBox(height: DesignTokens.spXs),
            const Text(
              'Video lessons work best when the linked YouTube video has captions or a transcript.',
              style: TextStyle(color: Colors.white70, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

class FilePreviewCard extends StatelessWidget {
  const FilePreviewCard({super.key, required this.file});

  final PlatformFile file;

  static String formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: DesignTokens.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.insert_drive_file_rounded,
                color: DesignTokens.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(formatSize(file.size),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: DesignTokens.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
