import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/study_progress_store.dart';
import '../../../../core/theme/design_tokens.dart';
import '../widgets/material_card.dart';
import '../widgets/material_widgets.dart';

class MaterialsContentView extends StatefulWidget {
  final bool dark;
  final List<Map<String, dynamic>> materials;
  final StudyMaterialProgress? latestMaterialProgress;
  final bool cachedMode;
  final bool lowDataMode;
  final String selectedType;
  final String searchQuery;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onClearFilters;
  final TextEditingController searchCtrl;

  const MaterialsContentView({
    super.key,
    required this.dark,
    required this.materials,
    this.latestMaterialProgress,
    required this.cachedMode,
    required this.lowDataMode,
    required this.selectedType,
    required this.searchQuery,
    required this.onTypeChanged,
    required this.onClearFilters,
    required this.searchCtrl,
  });

  @override
  State<MaterialsContentView> createState() => _MaterialsContentViewState();
}

class _MaterialsContentViewState extends State<MaterialsContentView> {
  final _progressStore = StudyProgressStore();

  List<Map<String, dynamic>> _filter() {
    var result = widget.materials;
    if (widget.selectedType != 'all') {
      result = result
          .where((m) =>
              (m['contentType'] ?? '').toString().toLowerCase() ==
              widget.selectedType)
          .toList();
    }
    if (widget.searchQuery.isNotEmpty) {
      final q = widget.searchQuery.toLowerCase();
      result = result
          .where((m) =>
              (m['title'] ?? '').toString().toLowerCase().contains(q) ||
              (m['subject']?['name'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(q) ||
              (m['description'] ?? '').toString().toLowerCase().contains(q))
          .toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filter();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: MaterialTypeFilterBar(
            selected: widget.selectedType,
            onSelect: widget.onTypeChanged,
          ).animate().fadeIn(),
        ),
        if (widget.cachedMode)
          SliverToBoxAdapter(
            child: MaterialInfoBanner(
              color: DesignTokens.warning,
              icon: Icons.offline_bolt_outlined,
              text: 'Showing cached materials while offline.',
              dark: widget.dark,
            ),
          ),
        if (widget.lowDataMode)
          SliverToBoxAdapter(
            child: MaterialInfoBanner(
              color: DesignTokens.info,
              icon: Icons.data_saver_on_outlined,
              text: 'Low-data mode on. Previews are lighter.',
              dark: widget.dark,
            ),
          ),
        SliverToBoxAdapter(
          child: FutureBuilder<StudyMaterialProgress?>(
            future: widget.latestMaterialProgress != null
                ? Future.value(widget.latestMaterialProgress)
                : _progressStore.loadLastMaterial(),
            builder: (context, snapshot) {
              final saved = snapshot.data;
              if (saved == null) return const SizedBox.shrink();
              return MaterialContinueCard(
                progress: saved,
                dark: widget.dark,
                onTap: () => context.push('/materials/${saved.slug}/read'),
              ).animate().fadeIn(delay: 100.ms);
            },
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    (widget.searchQuery.isNotEmpty ||
                            widget.selectedType != 'all')
                        ? '${filtered.length} result${filtered.length == 1 ? '' : 's'}'
                        : '${widget.materials.length} material${widget.materials.length == 1 ? '' : 's'}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: widget.dark
                          ? DesignTokens.darkTextSecondary
                          : DesignTokens.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (filtered.isEmpty &&
            (widget.searchQuery.isNotEmpty || widget.selectedType != 'all'))
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 64,
                      color: (widget.dark
                              ? DesignTokens.darkTextTertiary
                              : DesignTokens.textTertiary)
                          .withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('No materials match your filter.',
                      style: TextStyle(
                          color: widget.dark
                              ? DesignTokens.darkTextSecondary
                              : DesignTokens.textSecondary)),
                  const SizedBox(height: 12),
                  TextButton(
                      onPressed: widget.onClearFilters,
                      child: const Text('Clear filters')),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final m = filtered[i];
                  return MaterialCard(
                    material: m,
                    dark: widget.dark,
                    index: i,
                    onTap: () => context.push('/materials/${m['slug']}'),
                  );
                },
                childCount: filtered.length,
              ),
            ),
          ),
      ],
    );
  }
}
