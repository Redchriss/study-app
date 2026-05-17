import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/services/study_progress_store.dart';

class DashboardContinueStudyCard extends StatelessWidget {
  const DashboardContinueStudyCard({super.key, required this.progress});
  final StudyMaterialProgress progress;

  IconData get _icon {
    switch (progress.contentType.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf_rounded;
      case 'video': return Icons.play_circle_fill_rounded;
      case 'image': return Icons.image_rounded;
      default: return Icons.menu_book_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(DesignTokens.spMd, 0, DesignTokens.spMd, DesignTokens.spMd),
      child: AnimatedPress(
        onTap: () => context.push('/materials/${progress.slug}/read'),
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.spMd),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1B6CA8), Color(0xFF0D2E4A)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: const Color(0xFF1B6CA8).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                child: Icon(_icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: DesignTokens.spMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CONTINUE STUDYING', style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text(progress.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      progress.subjectName.isEmpty ? progress.progressLabel : '${progress.subjectName} · ${progress.progressLabel}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 5,
                              value: progress.completionRatio <= 0 ? 0.05 : progress.completionRatio,
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('${(progress.completionRatio * 100).toInt()}%', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardRecentMaterialCard extends StatelessWidget {
  final Map material;
  final bool dark;
  final VoidCallback onTap;
  const DashboardRecentMaterialCard({super.key, required this.material, required this.dark, required this.onTap});

  Color get _color {
    final name = (material['subject']?['name'] ?? '').toLowerCase();
    if (name.contains('math')) return DesignTokens.warning;
    if (name.contains('science') || name.contains('bio')) return DesignTokens.success;
    if (name.contains('english') || name.contains('chichewa')) return DesignTokens.primary;
    return DesignTokens.accent;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedPress(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: (dark ? DesignTokens.darkBorder : DesignTokens.border).withValues(alpha: 0.5)),
          boxShadow: DesignTokens.shadowSm(dark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: _color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.description_rounded, color: _color, size: 18)),
            const Spacer(),
            Text(material['title'] ?? '', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(material['subject']?['name'] ?? '', style: theme.textTheme.labelSmall?.copyWith(color: DesignTokens.textTertiary), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
