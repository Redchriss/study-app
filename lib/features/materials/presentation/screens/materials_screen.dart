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
                  .contains(q))
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
        onPressed: () => context.go('/upload-material'),
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
            return _buildShimmer();
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
            return _buildEmptyState(context);
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: DesignTokens.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu_book_outlined,
                size: 44, color: DesignTokens.primary),
          ),
          const SizedBox(height: 20),
          const Text(
            'No materials yet',
            style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Be the first to upload study materials\nfor your classmates.',
            textAlign: TextAlign.center,
            style: TextStyle(color: DesignTokens.textSecondary),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.go('/upload-material'),
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
          child: _TypeFilterBar(
            selected: _selectedType,
            onSelect: (t) => setState(() => _selectedType = t),
          ).animate().fadeIn(),
        ),

        // Banners
        if (cachedMode)
          SliverToBoxAdapter(
            child: _Banner(
              color: DesignTokens.warning,
              icon: Icons.offline_bolt_outlined,
              text: 'Showing cached materials while offline.',
            ),
          ),
        if (_lowDataMode)
          SliverToBoxAdapter(
            child: _Banner(
              color: DesignTokens.info,
              icon: Icons.data_saver_on_outlined,
              text: 'Low-data mode on. Previews are lighter.',
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
              return _ContinueCard(
                progress: saved,
                dark: dark,
                onTap: () =>
                    context.push('/materials/${saved.slug}/read'),
              ).animate().fadeIn(delay: 100.ms);
            },
          ),
        ),

        // Results count
        if (_searchQuery.isNotEmpty || _selectedType != 'all')
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                '${filtered.length} result${filtered.length == 1 ? '' : 's'}',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: DesignTokens.textSecondary),
              ),
            ),
          ),

        // Materials list
        if (filtered.isEmpty && (_searchQuery.isNotEmpty || _selectedType != 'all'))
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 64,
                      color: DesignTokens.textTertiary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text('No materials match your filter.',
                      style:
                          TextStyle(color: DesignTokens.textSecondary)),
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
                  return _MaterialCard(
                    material: m,
                    dark: dark,
                    index: i,
                    onTap: () => context.go('/materials/${m['slug']}'),
                  );
                },
                childCount: filtered.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(DesignTokens.spMd),
      itemCount: 8,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: DesignTokens.spSm),
        child: ShimmerBox(height: 80, radius: DesignTokens.radiusLg),
      ),
    );
  }
}

// ── Type Filter Bar ──────────────────────────────────────────────────────────
class _TypeFilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _TypeFilterBar({required this.selected, required this.onSelect});

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
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
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

// ── Continue Card ────────────────────────────────────────────────────────────
class _ContinueCard extends StatelessWidget {
  final StudyMaterialProgress progress;
  final bool dark;
  final VoidCallback onTap;
  const _ContinueCard(
      {required this.progress, required this.dark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: AnimatedPress(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B6CA8), Color(0xFF0D2E4A)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B6CA8).withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CONTINUE READING',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      progress.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      progress.subjectName.isEmpty
                          ? progress.progressLabel
                          : '${progress.subjectName} · ${progress.progressLabel}',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white60, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Material Card ─────────────────────────────────────────────────────────────
class _MaterialCard extends StatelessWidget {
  final Map<String, dynamic> material;
  final bool dark;
  final int index;
  final VoidCallback onTap;
  const _MaterialCard(
      {required this.material,
      required this.dark,
      required this.index,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _subjectColor(material['subject']?['name'] ?? '');
    final type = (material['contentType'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedPress(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (dark ? DesignTokens.darkBorder : DesignTokens.border)
                  .withValues(alpha: 0.5),
            ),
            boxShadow: DesignTokens.shadowSm(dark),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _typeIcon(type),
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material['title'] ?? '',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          material['subject']?['name'] ?? '',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: DesignTokens.textTertiary),
                        ),
                        if (material['educationLevel'] != null) ...[
                          const Text(' · ',
                              style: TextStyle(
                                  color: DesignTokens.textTertiary,
                                  fontSize: 11)),
                          Text(
                            _levelLabel(
                                material['educationLevel'].toString()),
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: DesignTokens.textTertiary),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          .animate(delay: Duration(milliseconds: 50 * (index % 10)))
          .fadeIn()
          .slideX(begin: 0.05),
    );
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  const _Banner({required this.color, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

Color _subjectColor(String name) {
  switch (name.toLowerCase()) {
    case 'english':
    case 'chichewa':
      return DesignTokens.primary;
    case 'mathematics':
      return DesignTokens.warning;
    case 'science':
    case 'biology':
    case 'chemistry':
      return DesignTokens.success;
    case 'social studies':
    case 'history':
      return DesignTokens.error;
    default:
      return DesignTokens.accent;
  }
}

IconData _typeIcon(String type) {
  switch (type.toLowerCase()) {
    case 'pdf':
      return Icons.picture_as_pdf_rounded;
    case 'video':
      return Icons.play_circle_rounded;
    case 'text':
      return Icons.article_rounded;
    case 'image':
      return Icons.image_rounded;
    default:
      return Icons.description_rounded;
  }
}

String _levelLabel(String level) {
  switch (level.toLowerCase()) {
    case 'primary':
      return 'Primary';
    case 'tertiary':
      return 'Uni';
    default:
      return 'Secondary';
  }
}
