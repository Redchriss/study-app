import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/services/app_preferences_service.dart';
import '../../../../core/services/material_cache_service.dart';
import '../../../../core/services/study_progress_store.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import 'materials_content_view.dart';
import 'materials_empty_state.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final _preferences = AppPreferencesService();
  final _cache = MaterialCacheService();
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
            return ListView.builder(
              padding: const EdgeInsets.all(DesignTokens.spMd),
              itemCount: 8,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.spSm),
                child: ShimmerBox(height: 108, radius: DesignTokens.radiusLg),
              ),
            );
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
                return MaterialsContentView(
                  dark: dark,
                  materials: cached,
                  latestMaterialProgress: null,
                  cachedMode: true,
                  lowDataMode: _lowDataMode,
                  selectedType: _selectedType,
                  searchQuery: _searchQuery,
                  onTypeChanged: (t) => setState(() => _selectedType = t),
                  onClearFilters: () => setState(() {
                    _searchQuery = '';
                    _searchCtrl.clear();
                    _selectedType = 'all';
                  }),
                  searchCtrl: _searchCtrl,
                );
              },
            );
          }

          if (rawMaterials.isEmpty) {
            return MaterialsEmptyState(dark: dark);
          }

          final materials = rawMaterials
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false);

          return MaterialsContentView(
            dark: dark,
            materials: materials,
            latestMaterialProgress: latestMaterialProgress,
            cachedMode: false,
            lowDataMode: _lowDataMode,
            selectedType: _selectedType,
            searchQuery: _searchQuery,
            onTypeChanged: (t) => setState(() => _selectedType = t),
            onClearFilters: () => setState(() {
              _searchQuery = '';
              _searchCtrl.clear();
              _selectedType = 'all';
            }),
            searchCtrl: _searchCtrl,
          );
        },
      ),
    );
  }

}
