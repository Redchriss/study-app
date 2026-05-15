import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/material_upload_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../materials/presentation/reader/material_reader_helpers.dart';

class UploadSuccessSheet extends StatelessWidget {
  const UploadSuccessSheet({
    super.key,
    required this.result,
  });

  final MaterialUploadResult result;

  @override
  Widget build(BuildContext context) {
    final canPreview = (result.slug ?? '').isNotEmpty;
    final isApproved = result.isApproved == true;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF3E1A8), Color(0xFFCDEBE2)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: DesignTokens.primary),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isApproved ? 'Material is ready to study' : 'Upload submitted for review',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.message ?? 'Your material is now in the study pipeline.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: DesignTokens.textSecondary,
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if ((result.title ?? '').isNotEmpty)
              _MetaRow(label: 'Material', value: result.title!),
            if ((result.subjectName ?? '').isNotEmpty)
              _MetaRow(label: 'Subject', value: result.subjectName!),
            if ((result.contentType ?? '').isNotEmpty)
              _MetaRow(label: 'Type', value: result.contentType!.toUpperCase()),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F7F1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: DesignTokens.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome, color: DesignTokens.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      describeAiReadiness(result.aiReadiness),
                      style: const TextStyle(height: 1.5, color: DesignTokens.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (canPreview)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final router = GoRouter.of(context);
                    Navigator.of(context).pop();
                    router.push('/materials/${result.slug}/read');
                  },
                  icon: const Icon(Icons.chrome_reader_mode_rounded),
                  label: Text(isApproved ? 'Open In Study Mode' : 'Preview Study Mode'),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final router = GoRouter.of(context);
                  Navigator.of(context).pop();
                  router.push('/my-uploads');
                },
                icon: const Icon(Icons.folder_special_outlined),
                label: const Text('Go To My Uploads'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Keep Uploading'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 74,
            child: Text(
              label,
              style: const TextStyle(
                color: DesignTokens.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
