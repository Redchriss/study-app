import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../../core/graphql/queries/queries.dart';
import '../../../../../core/services/haptic_service.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../materials/presentation/widgets/material_card.dart';
import 'study_filter_chips.dart';

enum _SortMode { newest, mostViewed }

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
  String _subject = 'all';
  _SortMode _sort = _SortMode.newest;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _applyFilters(List rawMaterials) {
    final filtered = rawMaterials
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((m) {
      if (_type != 'all' &&
          (m['contentType'] ?? '').toString().toLowerCase() != _type) {
        return false;
      }
      if (_subject != 'all') {
        final subjectName =
            (m['subject']?['name'] ?? '').toString().toLowerCase();
        if (subjectName != _subject.toLowerCase()) return false;
      }
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return (m['title'] ?? '').toString().toLowerCase().contains(q) ||
            (m['subject']?['name'] ?? '').toString().toLowerCase().contains(q);
      }
      return true;
    }).toList();

    if (_sort == _SortMode.mostViewed) {
      filtered.sort((a, b) {
        final va = (a['viewsCount'] as num?)?.toInt() ?? 0;
        final vb = (b['viewsCount'] as num?)?.toInt() ?? 0;
        return vb.compareTo(va);
      });
    }
    return filtered;
  }

  Set<String> _extractSubjects(List rawMaterials) {
    final subjects = <String>{};
    for (final m in rawMaterials) {
      if (m is Map) {
        final name = m['subject']?['name']?.toString();
        if (name != null && name.isNotEmpty) subjects.add(name);
      }
    }
    return subjects..toList().sort();
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
        final materials = _applyFilters(rawMaterials);
        final subjectNames = _extractSubjects(rawMaterials);

        return Column(
          children: [
            _SearchBar(
              ctrl: _ctrl,
              dark: widget.dark,
              resultCount: materials.length,
              totalCount: rawMaterials.length,
              onChanged: (v) => setState(() => _search = v),
              onClear: () => setState(() => _search = _ctrl.text = ''),
            ),
            StudyFilterChips(
              type: _type,
              sort: _sort.name,
              subject: _subject,
              subjects: subjectNames.toList(),
              dark: widget.dark,
              onTypeChanged: (t) {
                HapticService.selection();
                setState(() => _type = t);
              },
              onSortChanged: (s) {
                HapticService.selection();
                setState(() => _sort = _SortMode.values.firstWhere(
                    (e) => e.name == s,
                    orElse: () => _SortMode.newest));
              },
              onSubjectChanged: (s) {
                HapticService.selection();
                setState(() => _subject = s);
              },
            ),
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
                          ? EmptyState(
                              icon: Icons.menu_book_outlined,
                              title: _search.isNotEmpty || _type != 'all'
                                  ? 'No matches'
                                  : 'No materials yet',
                              subtitle: _search.isNotEmpty || _type != 'all'
                                  ? 'Try adjusting your filters or search terms.'
                                  : 'Materials for your level will appear here.',
                            )
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

class _SearchBar extends StatelessWidget {
  final TextEditingController ctrl;
  final bool dark;
  final int resultCount;
  final int totalCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.ctrl,
    required this.dark,
    required this.resultCount,
    required this.totalCount,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: 'Search materials...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: onClear)
                    : null,
                filled: true,
                fillColor: dark
                    ? DesignTokens.darkSurfaceVariant
                    : DesignTokens.surfaceVariant,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              onChanged: onChanged,
            ),
          ),
          if (totalCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: DesignTokens.primary.withValues(alpha: dark ? 0.2 : 0.08),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: Text(
                '$resultCount',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: DesignTokens.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
