import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class CircleHeroBanner extends StatelessWidget {
  const CircleHeroBanner({super.key, required this.circle, required this.dark});
  final Map<String, dynamic> circle;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [DesignTokens.darkSurface, DesignTokens.darkSurfaceVariant]
              : const [Color(0xFFE9F4FF), Color(0xFFF7F1DE)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  circle['isMember'] == true
                      ? 'Study together'
                      : 'Join this study circle',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  circle['isMember'] == true
                      ? 'Ask questions, share resources, and work through stuck points with your level.'
                      : 'Become a member to ask questions and share revision resources.',
                  style: const TextStyle(
                      color: DesignTokens.textSecondary, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Text('${circle['memberCount'] ?? 0}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 18)),
                const Text('members',
                    style: TextStyle(
                        fontSize: 12, color: DesignTokens.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CircleFilterBar extends StatelessWidget {
  const CircleFilterBar({
    super.key,
    required this.sort,
    required this.typeFilter,
    required this.solvedOnly,
    required this.onSortChanged,
    required this.onTypeFilterChanged,
    required this.onSolvedOnlyChanged,
    required this.onToggleNewPost,
    required this.showNewPost,
  });

  final String sort;
  final String typeFilter;
  final bool solvedOnly;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<String> onTypeFilterChanged;
  final ValueChanged<bool> onSolvedOnlyChanged;
  final VoidCallback onToggleNewPost;
  final bool showNewPost;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spMd, vertical: DesignTokens.spXs),
          child: Row(children: [
            ChoiceChip(
                label: const Text('Hot'),
                selected: sort == 'hot',
                onSelected: (_) => onSortChanged('hot')),
            const SizedBox(width: 6),
            ChoiceChip(
                label: const Text('New'),
                selected: sort == 'new',
                onSelected: (_) => onSortChanged('new')),
            const SizedBox(width: 6),
            ChoiceChip(
                label: const Text('Top'),
                selected: sort == 'top',
                onSelected: (_) => onSortChanged('top')),
            const Spacer(),
            AnimatedPress(
              onTap: onToggleNewPost,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    color: DesignTokens.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add, size: 16, color: DesignTokens.primary),
                  SizedBox(width: 4),
                  Text('Post',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: DesignTokens.primary)),
                ]),
              ),
            ),
          ]),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spMd),
          child: Row(
            children: [
              for (final filter in const [
                ('all', 'All'),
                ('question', 'Questions'),
                ('resource', 'Resources'),
                ('discussion', 'Discussion')
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter.$2),
                    selected: typeFilter == filter.$1,
                    onSelected: (_) => onTypeFilterChanged(filter.$1),
                  ),
                ),
              FilterChip(
                label: const Text('Solved only'),
                selected: solvedOnly,
                onSelected: onSolvedOnlyChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
