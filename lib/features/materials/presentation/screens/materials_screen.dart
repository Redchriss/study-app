import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/services/app_preferences_service.dart';
import '../../../../core/services/material_cache_service.dart';
import '../../../../core/services/study_progress_store.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../widgets/material_widgets.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final _preferences = AppPreferencesService();
  final _cache = MaterialCacheService();
  final _progressStore = StudyProgressStore();
  final _searchCtrl = TextEditingController();

  bool _lowDataMode = false;
  String _searchQuery = '';
  String _selectedType = 'all';
  bool _searchActive = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final lowDataMode = await _preferences.isLowDataMode();
    if (mounted) {
      setState(() => _lowDataMode = lowDataMode);
    }
  }

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> materials) {
    var result = materials;
    if (_selectedType != 'all') {
      result = result
          .where((m) =>
              (m['contentType'] ?? '').toString().toLowerCase() ==
              _selectedType)
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
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
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: _searchActive
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search materials...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : Text(
                'Materials',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
        centerTitle: !_searchActive,
        actions: [
          if (!_searchActive)
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () => setState(() => _searchActive = true),
              tooltip: 'Search',
            ),
          if (_searchActive)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => setState(() {
                _searchActive = false;
                _searchQuery = '';
                _searchCtrl.clear();
              }),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/upload-material'),
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('Upload'),
        tooltip: 'Upload a study material',
      ),
      body: Query(
        options: QueryOptions(
          document: gql(kMaterials),
          variables: {'limit': _lowDataMode ? 20 : 50},
          fetchPolicy: FetchPolicy.cacheAndNetwork,
        ),
        builder: (result, {fetchMore, refetch}) {
          if (result.isLoading && result.data == null) {
            return _buildShimmer(dark);
          }

          final rawMaterials = (result.data?['materials'] as List?) ?? [];
          if (rawMaterials.isNotEmpty) {
            _cache.saveMaterialsList(rawMaterials);
          }

          final latestMaterialProgress = StudyMaterialProgress.fromGraphQL(
            result.data?['latestMaterialProgress'] is Map
                ? Map<String, dynamic>.from(
                    result.data!['latestMaterialProgress'] as Map)
                : null,
          );

          if (result.hasException && rawMaterials.isEmpty) {
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: _cache.loadMaterialsList(),
              builder: (context, snapshot) {
                final cached = snapshot.data ?? const [];
                if (cached.isEmpty) {
                  return ErrorState(
                    message: 'Could not load. Check your connection.',
                    onRetry: () => refetch?.call(),
                  );
                }
                return _buildContent(
                  context: context,
                  theme: theme,
                  dark: dark,
                  materials: cached,
                  latestMaterialProgress: latestMaterialProgress,
                  cachedMode: true,
                );
              },
            );
          }

          if (rawMaterials.isEmpty) {
            return _buildEmptyState(context, dark);
          }

          final materials = rawMaterials
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false);

          return RefreshIndicator(
            onRefresh: () async => refetch?.call(),
            child: _buildContent(
              context: context,
              theme: theme,
              dark: dark,
              materials: materials,
              latestMaterialProgress: latestMaterialProgress,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool dark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: DesignTokens.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 18,
                  left: 18,
                  child: Container(
                    width: 28,
                    height: 36,
                    decoration: BoxDecoration(
                      color: DesignTokens.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 18,
                  right: 18,
                  child: Container(
                    width: 28,
                    height: 36,
                    decoration: BoxDecoration(
                      color: DesignTokens.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const Icon(Icons.menu_book_rounded,
                    size: 40, color: DesignTokens.primary),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No materials yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: dark ? DesignTokens.darkTextPrimary : DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to upload study materials\nfor your classmates.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: dark ? DesignTokens.darkTextSecondary : DesignTokens.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push('/upload-material'),
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Upload Material'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required ThemeData theme,
    required bool dark,
    required List<Map<String, dynamic>> materials,
    required StudyMaterialProgress? latestMaterialProgress,
    bool cachedMode = false,
  }) {
    final filtered = _filter(materials);

    return CustomScrollView(
      slivers: [
        // Type filter chips
        SliverToBoxAdapter(
          child: MaterialTypeFilterBar(
            selected: _selectedType,
            onSelect: (t) => setState(() => _selectedType = t),
          ).animate().fadeIn(),
        ),

        // Banners
        if (cachedMode)
          SliverToBoxAdapter(
            child: MaterialInfoBanner(
              color: DesignTokens.warning,
              icon: Icons.offline_bolt_outlined,
              text: 'Showing cached materials while offline.',
              dark: dark,
            ),
          ),
        if (_lowDataMode)
          SliverToBoxAdapter(
            child: MaterialInfoBanner(
              color: DesignTokens.info,
              icon: Icons.data_saver_on_outlined,
              text: 'Low-data mode on. Previews are lighter.',
              dark: dark,
            ),
          ),

        // Continue studying
        SliverToBoxAdapter(
          child: FutureBuilder<StudyMaterialProgress?>(
            future: latestMaterialProgress != null
                ? Future.value(latestMaterialProgress)
                : _progressStore.loadLastMaterial(),
            builder: (context, snapshot) {
              final saved = snapshot.data;
              if (saved == null) return const SizedBox.shrink();
              return MaterialContinueCard(
                progress: saved,
                dark: dark,
                onTap: () =>
                    context.push('/materials/${saved.slug}/read'),
              ).animate().fadeIn(delay: 100.ms);
            },
          ),
        ),

        // Section header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    (_searchQuery.isNotEmpty || _selectedType != 'all')
                        ? '${filtered.length} result${filtered.length == 1 ? '' : 's'}'
                        : '${materials.length} material${materials.length == 1 ? '' : 's'}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: dark
                          ? DesignTokens.darkTextSecondary
                          : DesignTokens.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Materials list
        if (filtered.isEmpty &&
            (_searchQuery.isNotEmpty || _selectedType != 'all'))
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 64,
                      color: (dark
                              ? DesignTokens.darkTextTertiary
                              : DesignTokens.textTertiary)
                          .withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No materials match your filter.',
                    style: TextStyle(
                      color: dark
                          ? DesignTokens.darkTextSecondary
                          : DesignTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() {
                      _searchQuery = '';
                      _searchCtrl.clear();
                      _selectedType = 'all';
                    }),
                    child: const Text('Clear filters'),
                  ),
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
                    dark: dark,
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

  Widget _buildShimmer(bool dark) {
    return ListView.builder(
      padding: const EdgeInsets.all(DesignTokens.spMd),
      itemCount: 8,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: DesignTokens.spSm),
        child: ShimmerBox(height: 108, radius: DesignTokens.radiusLg),
      ),
    );
  }
}
