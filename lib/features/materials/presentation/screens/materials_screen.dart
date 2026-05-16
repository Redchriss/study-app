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
              dark: dark,
            ),
          ),
        if (_lowDataMode)
          SliverToBoxAdapter(
            child: _Banner(
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
              return _ContinueCard(
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
                  return _MaterialCard(
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

// ── Continue Card ────────────────────────────────────────────────────────────
class _ContinueCard extends StatelessWidget {
  final StudyMaterialProgress progress;
  final bool dark;
  final VoidCallback onTap;
  const _ContinueCard(
      {required this.progress, required this.dark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
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
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Progress arc
              SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress.completionRatio,
                      strokeWidth: 3,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    Center(
                      child: Text(
                        '${(progress.completionRatio * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
    final subjectName = (material['subject']?['name'] ?? '') as String;
    final type = (material['contentType'] ?? '').toString();
    final typeColor = _typeColor(type);
    final accentColor = _subjectColor(subjectName);
    final description = (material['description'] ?? '').toString().trim();
    final aiSummary = (material['aiSummary'] ?? '').toString().trim();
    final snippet = description.isNotEmpty ? description : aiSummary;
    final views = (material['viewsCount'] ?? 0) as int;
    final isPremium = material['isPremium'] == true;
    final isBookmarked = material['isBookmarked'] == true;
    final level = _levelLabel((material['educationLevel'] ?? '').toString());

    final surfaceColor = dark ? DesignTokens.darkSurface : DesignTokens.surface;
    final borderColor = dark ? DesignTokens.darkBorder : DesignTokens.border;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedPress(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(color: borderColor.withValues(alpha: 0.5)),
            boxShadow: DesignTokens.shadowSm(dark),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left accent bar
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(DesignTokens.radiusLg),
                        bottomLeft: Radius.circular(DesignTokens.radiusLg),
                      ),
                    ),
                  ),

                  // Icon column
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 14, 0, 14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(DesignTokens.radiusMd),
                          ),
                          child: Icon(
                            _typeIcon(type),
                            color: typeColor,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Main content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title row
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  material['title'] ?? '',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: dark
                                        ? DesignTokens.darkTextPrimary
                                        : DesignTokens.textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (isPremium)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: DesignTokens.warning
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    'PRO',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: DesignTokens.warning,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          // Description snippet
                          if (snippet.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              snippet,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: dark
                                    ? DesignTokens.darkTextSecondary
                                    : DesignTokens.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],

                          const SizedBox(height: 8),

                          // Meta row
                          Row(
                            children: [
                              // Type badge
                              _TypeBadge(type: type, color: typeColor),
                              const SizedBox(width: 6),
                              // Subject tag
                              if (subjectName.isNotEmpty)
                                _MetaChip(
                                  label: subjectName,
                                  color: accentColor,
                                  dark: dark,
                                ),
                              const Spacer(),
                              // Level + views
                              if (level.isNotEmpty)
                                Text(
                                  level,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: dark
                                        ? DesignTokens.darkTextTertiary
                                        : DesignTokens.textTertiary,
                                  ),
                                ),
                              if (views > 0) ...[
                                Text(
                                  ' · ',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: dark
                                        ? DesignTokens.darkTextTertiary
                                        : DesignTokens.textTertiary,
                                  ),
                                ),
                                Icon(
                                  Icons.visibility_outlined,
                                  size: 11,
                                  color: dark
                                      ? DesignTokens.darkTextTertiary
                                      : DesignTokens.textTertiary,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  _formatViews(views),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: dark
                                        ? DesignTokens.darkTextTertiary
                                        : DesignTokens.textTertiary,
                                  ),
                                ),
                              ],
                              if (isBookmarked) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.bookmark_rounded,
                                  size: 14,
                                  color: DesignTokens.primary
                                      .withValues(alpha: 0.7),
                                ),
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
      )
          .animate(delay: Duration(milliseconds: 40 * (index % 12)))
          .fadeIn()
          .slideY(begin: 0.04),
    );
  }
}

// ── Type Badge ────────────────────────────────────────────────────────────────
class _TypeBadge extends StatelessWidget {
  final String type;
  final Color color;
  const _TypeBadge({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_typeIcon(type), size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            type.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Meta Chip ─────────────────────────────────────────────────────────────────
class _MetaChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool dark;
  const _MetaChip({required this.label, required this.color, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Banner ────────────────────────────────────────────────────────────────────
class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  final bool dark;
  const _Banner(
      {required this.color,
      required this.icon,
      required this.text,
      required this.dark});

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
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: dark
                    ? DesignTokens.darkTextPrimary
                    : DesignTokens.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

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

Color _typeColor(String type) {
  switch (type.toLowerCase()) {
    case 'pdf':
      return const Color(0xFFE74C3C); // red
    case 'video':
      return const Color(0xFF9B59B6); // purple
    case 'text':
      return DesignTokens.primary; // blue
    case 'image':
      return DesignTokens.success; // green
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
    case 'secondary':
      return 'Secondary';
    default:
      return '';
  }
}

String _formatViews(int views) {
  if (views >= 1000) return '${(views / 1000).toStringAsFixed(1)}k';
  return '$views';
}
