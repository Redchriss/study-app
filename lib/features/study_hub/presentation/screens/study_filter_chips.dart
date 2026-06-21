import 'package:flutter/material.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/widgets/subject_color_chip.dart';

class StudyFilterChips extends StatelessWidget {
  final String type;
  final String sort;
  final String subject;
  final List<String> subjects;
  final bool dark;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<String> onSubjectChanged;

  const StudyFilterChips({
    super.key,
    required this.type,
    required this.sort,
    required this.subject,
    required this.subjects,
    required this.dark,
    required this.onTypeChanged,
    required this.onSortChanged,
    required this.onSubjectChanged,
  });

  static const _typeFilters = [
    ('all', 'All', Icons.auto_awesome_rounded, SubjectColors.defaultColor),
    ('pdf', 'PDF', Icons.picture_as_pdf_rounded, Color(0xFFE74C3C)),
    ('text', 'Text', Icons.article_rounded, SubjectColors.science),
    ('video', 'Video', Icons.play_circle_rounded, SubjectColors.physics),
  ];

  static const _sortFilters = [
    ('newest', 'Newest', Icons.schedule_rounded),
    ('mostViewed', 'Popular', Icons.trending_up_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _typeFilters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final (val, label, icon, color) = _typeFilters[i];
              final isSelected = type == val;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: GestureDetector(
                  onTap: () => onTypeChanged(val),
                  child: AnimatedContainer(
                    duration: DesignTokens.durFast,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(colors: [
                              color,
                              color.withValues(alpha: 0.7),
                            ])
                          : null,
                      color: isSelected ? null : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : color.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon,
                            size: 14,
                            color: isSelected ? Colors.white : color),
                        const SizedBox(width: 5),
                        Text(label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? Colors.white : color,
                            )),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(
          height: 36,
          child: Row(
            children: [
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _sortFilters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final (val, label, icon) = _sortFilters[i];
                    final isSelected = sort == val;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: GestureDetector(
                        onTap: () => onSortChanged(val),
                        child: AnimatedContainer(
                          duration: DesignTokens.durFast,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? DesignTokens.primary.withValues(
                                    alpha: dark ? 0.2 : 0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isSelected
                                  ? DesignTokens.primary.withValues(alpha: 0.3)
                                  : (dark
                                          ? DesignTokens.darkBorder
                                          : DesignTokens.border)
                                      .withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon,
                                  size: 12,
                                  color: isSelected
                                      ? DesignTokens.primary
                                      : DesignTokens.textTertiary),
                              const SizedBox(width: 4),
                              Text(label.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? DesignTokens.primary
                                        : DesignTokens.textTertiary,
                                    letterSpacing: 0.3,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (subjects.length > 1)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _SubjectDropdown(
                    subjects: subjects,
                    selected: subject,
                    dark: dark,
                    onChanged: onSubjectChanged,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubjectDropdown extends StatelessWidget {
  final List<String> subjects;
  final String selected;
  final bool dark;
  final ValueChanged<String> onChanged;

  const _SubjectDropdown({
    required this.subjects,
    required this.selected,
    required this.dark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final displayLabel =
        selected == 'all' ? 'Subject' : selected;
    return PopupMenuButton<String>(
      initialValue: selected,
      onSelected: onChanged,
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd)),
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'all', child: Text('All Subjects')),
        ...subjects.map((s) => PopupMenuItem(value: s, child: Text(s))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected != 'all'
              ? DesignTokens.accent.withValues(alpha: dark ? 0.2 : 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected != 'all'
                ? DesignTokens.accent.withValues(alpha: 0.3)
                : (dark ? DesignTokens.darkBorder : DesignTokens.border)
                    .withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list_rounded,
                size: 12,
                color: selected != 'all'
                    ? DesignTokens.accent
                    : DesignTokens.textTertiary),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(displayLabel,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected != 'all'
                        ? DesignTokens.accent
                        : DesignTokens.textTertiary,
                  )),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down_rounded,
                size: 16,
                color: selected != 'all'
                    ? DesignTokens.accent
                    : DesignTokens.textTertiary),
          ],
        ),
      ),
    );
  }
}
