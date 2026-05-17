import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/services/study_progress_store.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Color materialSubjectColor(String name) {
  switch (name.toLowerCase()) {
    case 'english':
    case 'chichewa': return DesignTokens.primary;
    case 'mathematics': return DesignTokens.warning;
    case 'science':
    case 'biology':
    case 'chemistry': return DesignTokens.success;
    case 'social studies':
    case 'history': return DesignTokens.error;
    default: return DesignTokens.accent;
  }
}

Color materialTypeColor(String type) {
  switch (type.toLowerCase()) {
    case 'pdf': return const Color(0xFFE74C3C);
    case 'video': return const Color(0xFF9B59B6);
    case 'text': return DesignTokens.primary;
    case 'image': return DesignTokens.success;
    default: return DesignTokens.accent;
  }
}

IconData materialTypeIcon(String type) {
  switch (type.toLowerCase()) {
    case 'pdf': return Icons.picture_as_pdf_rounded;
    case 'video': return Icons.play_circle_rounded;
    case 'text': return Icons.article_rounded;
    case 'image': return Icons.image_rounded;
    default: return Icons.description_rounded;
  }
}

String materialLevelLabel(String level) {
  switch (level.toLowerCase()) {
    case 'primary': return 'Primary';
    case 'tertiary': return 'Uni';
    case 'secondary': return 'Secondary';
    default: return '';
  }
}

String materialFormatViews(int views) {
  if (views >= 1000) return '${(views / 1000).toStringAsFixed(1)}k';
  return '$views';
}

// ── Type Filter Bar ───────────────────────────────────────────────────────────

class MaterialTypeFilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const MaterialTypeFilterBar({super.key, required this.selected, required this.onSelect});

  static const _types = [
    ('all', 'All', Icons.grid_view_rounded),
    ('pdf', 'PDF', Icons.picture_as_pdf_rounded),
    ('video', 'Video', Icons.play_circle_rounded),
    ('text', 'Notes', Icons.article_rounded),
    ('image', 'Images', Icons.image_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final type = _types[i];
          final isSelected = selected == type.$1;
          return FilterChip(
            selected: isSelected,
            avatar: Icon(type.$3, size: 16),
            label: Text(type.$2),
            onSelected: (_) => onSelect(type.$1),
            showCheckmark: false,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }
}

// ── Continue Card ─────────────────────────────────────────────────────────────

class MaterialContinueCard extends StatelessWidget {
  final StudyMaterialProgress progress;
  final bool dark;
  final VoidCallback onTap;
  const MaterialContinueCard({super.key, required this.progress, required this.dark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: AnimatedPress(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1B6CA8), Color(0xFF0D2E4A)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: const Color(0xFF1B6CA8).withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CONTINUE READING', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    const SizedBox(height: 3),
                    Text(progress.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(
                      progress.subjectName.isEmpty ? progress.progressLabel : '${progress.subjectName} · ${progress.progressLabel}',
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 40, height: 40,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(value: progress.completionRatio, strokeWidth: 3, backgroundColor: Colors.white.withValues(alpha: 0.2), valueColor: const AlwaysStoppedAnimation<Color>(Colors.white)),
                    Center(child: Text('${(progress.completionRatio * 100).round()}%', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white60, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Material Card ─────────────────────────────────────────────────────────────

class MaterialCard extends StatelessWidget {
  final Map<String, dynamic> material;
  final bool dark;
  final int index;
  final VoidCallback onTap;
  const MaterialCard({super.key, required this.material, required this.dark, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjectName = (material['subject']?['name'] ?? '') as String;
    final type = (material['contentType'] ?? '').toString();
    final typeColor = materialTypeColor(type);
    final accentColor = materialSubjectColor(subjectName);
    final description = (material['description'] ?? '').toString().trim();
    final aiSummary = (material['aiSummary'] ?? '').toString().trim();
    final snippet = description.isNotEmpty ? description : aiSummary;
    final views = (material['viewsCount'] ?? 0) as int;
    final isPremium = material['isPremium'] == true;
    final isBookmarked = material['isBookmarked'] == true;
    final level = materialLevelLabel((material['educationLevel'] ?? '').toString());

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedPress(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(color: (dark ? DesignTokens.darkBorder : DesignTokens.border).withValues(alpha: 0.5)),
            boxShadow: DesignTokens.shadowSm(dark),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(DesignTokens.radiusLg), bottomLeft: Radius.circular(DesignTokens.radiusLg)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 14, 0, 14),
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(DesignTokens.radiusMd)),
                      child: Icon(materialTypeIcon(type), color: typeColor, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(material['title'] ?? '', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis)),
                              if (isPremium) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: DesignTokens.warning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                                  child: const Text('PRO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: DesignTokens.warning, letterSpacing: 0.5)),
                                ),
                              ],
                            ],
                          ),
                          if (snippet.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(snippet, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: dark ? DesignTokens.darkTextSecondary : DesignTokens.textSecondary, height: 1.4)),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _TypeBadge(type: type, color: typeColor),
                              const SizedBox(width: 6),
                              if (subjectName.isNotEmpty) _MetaChip(label: subjectName, color: accentColor, dark: dark),
                              const Spacer(),
                              if (level.isNotEmpty) Text(level, style: TextStyle(fontSize: 10, color: dark ? DesignTokens.darkTextTertiary : DesignTokens.textTertiary)),
                              if (views > 0) ...[
                                Text(' · ', style: TextStyle(fontSize: 10, color: dark ? DesignTokens.darkTextTertiary : DesignTokens.textTertiary)),
                                Icon(Icons.visibility_outlined, size: 11, color: dark ? DesignTokens.darkTextTertiary : DesignTokens.textTertiary),
                                const SizedBox(width: 2),
                                Text(materialFormatViews(views), style: TextStyle(fontSize: 10, color: dark ? DesignTokens.darkTextTertiary : DesignTokens.textTertiary)),
                              ],
                              if (isBookmarked) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.bookmark_rounded, size: 14, color: DesignTokens.primary.withValues(alpha: 0.7)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ).animate(delay: Duration(milliseconds: 40 * (index % 12))).fadeIn().slideY(begin: 0.04),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  final Color color;
  const _TypeBadge({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withValues(alpha: 0.25))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(materialTypeIcon(type), size: 10, color: color),
          const SizedBox(width: 3),
          Text(type.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool dark;
  const _MetaChip({required this.label, required this.color, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ── Banner ────────────────────────────────────────────────────────────────────

class MaterialInfoBanner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  final bool dark;
  const MaterialInfoBanner({super.key, required this.color, required this.icon, required this.text, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dark ? DesignTokens.darkTextPrimary : DesignTokens.textPrimary))),
        ],
      ),
    );
  }
}
