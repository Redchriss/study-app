import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class UploadsSummaryCard extends StatelessWidget {
  const UploadsSummaryCard({
    super.key,
    required this.totalCount,
    required this.liveCount,
    required this.pendingCount,
  });

  final int totalCount;
  final int liveCount;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [DesignTokens.darkSurface, DesignTokens.darkSurfaceVariant]
              : const [Color(0xFFF5E8BF), Color(0xFFE0F0EB)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your material pipeline',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Keep your library growing. Live materials can already help students, while pending ones are waiting for review.',
            style: TextStyle(color: DesignTokens.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _UploadsMetric(label: 'Total', value: '$totalCount')),
              const SizedBox(width: 10),
              Expanded(child: _UploadsMetric(label: 'Live', value: '$liveCount')),
              const SizedBox(width: 10),
              Expanded(child: _UploadsMetric(label: 'Pending', value: '$pendingCount')),
            ],
          ),
        ],
      ),
    );
  }
}

class _UploadsMetric extends StatelessWidget {
  const _UploadsMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: DesignTokens.textSecondary, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class MyUploadMaterialCard extends StatelessWidget {
  final Map<String, dynamic> material;
  final VoidCallback? onDelete;

  const MyUploadMaterialCard({
    super.key,
    required this.material,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final slug = material['slug'] as String? ?? '';
    final title = material['title'] as String? ?? '';
    final subject = material['subject']?['name'] as String? ?? '';
    final type = (material['contentType'] as String? ?? '').toUpperCase();
    final approved = material['isApproved'] == true;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedPress(
      onTap: slug.isEmpty ? null : () => context.push('/materials/$slug'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: dark ? DesignTokens.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DesignTokens.primary.withValues(alpha: 0.15)),
          boxShadow: DesignTokens.shadowSm(dark),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: approved 
                    ? DesignTokens.success.withValues(alpha: 0.1) 
                    : DesignTokens.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                approved ? Icons.cloud_done_rounded : Icons.pending_actions_rounded,
                color: approved ? DesignTokens.success : DesignTokens.warning,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, 
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (subject.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: dark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            subject,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: DesignTokens.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (type.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: DesignTokens.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            type,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: DesignTokens.primary),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!approved)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: DesignTokens.error),
                tooltip: 'Delete pending upload',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onDelete,
              )
            else
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Icon(Icons.chevron_right_rounded, color: DesignTokens.textTertiary),
              ),
          ],
        ),
      ),
    );
  }
}
