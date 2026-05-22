import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import 'material_helpers.dart';

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
