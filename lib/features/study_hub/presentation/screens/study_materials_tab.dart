import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../../core/graphql/queries/queries.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../materials/presentation/widgets/material_card.dart';

class StudyMaterialsTab extends StatefulWidget {
  final bool dark;
  const StudyMaterialsTab({super.key, required this.dark});

  @override
  State<StudyMaterialsTab> createState() => _StudyMaterialsTabState();
}

class _StudyMaterialsTabState extends State<StudyMaterialsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _search = '';
  String _type = 'all';
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Query(
      options: QueryOptions(
        document: gql(kMaterials),
        variables: const {'limit': 50},
        fetchPolicy: FetchPolicy.cacheAndNetwork,
      ),
      builder: (result, {fetchMore, refetch}) {
        final rawMaterials = (result.data?['materials'] as List?) ?? [];
        final materials = rawMaterials
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where((m) {
          if (_type != 'all' &&
              (m['contentType'] ?? '').toString().toLowerCase() != _type) {
            return false;
          }
          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            return (m['title'] ?? '').toString().toLowerCase().contains(q) ||
                (m['subject']?['name'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(q);
          }
          return true;
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  hintText: 'Search materials...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () =>
                              setState(() => _search = _ctrl.text = ''),
                        )
                      : null,
                  filled: true,
                  fillColor: widget.dark
                      ? DesignTokens.darkSurfaceVariant
                      : DesignTokens.surfaceVariant,
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusMd),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            _TypeFilterBar(
                selected: _type, onSelect: (t) => setState(() => _type = t)),
            Expanded(
              child: result.isLoading && rawMaterials.isEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: 6,
                      itemBuilder: (_, __) => const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: ShimmerBox(
                              height: 108, radius: DesignTokens.radiusLg)),
                    )
                  : result.hasException && rawMaterials.isEmpty
                      ? ErrorState(
                          message: graphQLErrorMessage(
                              result.exception, 'Could not load materials.'),
                          onRetry: () => refetch?.call(),
                        )
                      : materials.isEmpty
                          ? const EmptyState(
                              icon: Icons.menu_book_outlined,
                              title: 'No materials found',
                              subtitle: 'Try adjusting your filters.')
                          : RefreshIndicator(
                              onRefresh: () async => refetch?.call(),
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 4, 12, 100),
                                itemCount: materials.length,
                                itemBuilder: (_, i) {
                                  final slug =
                                      materials[i]['slug']?.toString() ?? '';
                                  return MaterialCard(
                                    material: materials[i],
                                    dark: widget.dark,
                                    index: i,
                                    onTap: slug.isEmpty
                                        ? () {}
                                        : () => context.push(
                                              '/materials/$slug',
                                            ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        );
      },
    );
  }
}

class _TypeFilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _TypeFilterBar({required this.selected, required this.onSelect});

  static const _filters = [
    ('all', 'All'),
    ('pdf', 'PDF'),
    ('text', 'Text'),
    ('video', 'Video'),
    ('youtube', 'YouTube'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: _filters.map((f) {
          final (val, label) = f;
          final sel = selected == val;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : DesignTokens.textSecondary)),
              selected: sel,
              onSelected: (_) => onSelect(val),
              selectedColor: DesignTokens.primary,
              backgroundColor: Colors.transparent,
              side: BorderSide(
                  color: sel
                      ? DesignTokens.primary
                      : DesignTokens.border.withValues(alpha: 0.6)),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }
}
