import 'package:flutter/material.dart';
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

  bool _lowDataMode = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
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
        title: Text(
          'Materials',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
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

          final materials = (result.data?['materials'] as List?) ?? [];
          if (materials.isNotEmpty) {
            _cache.saveMaterialsList(materials);
          }

          final latestMaterialProgress = StudyMaterialProgress.fromGraphQL(
            result.data?['latestMaterialProgress'] is Map
                ? Map<String, dynamic>.from(result.data!['latestMaterialProgress'] as Map)
                : null,
          );

          if (result.hasException && materials.isEmpty) {
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: _cache.loadMaterialsList(),
              builder: (context, snapshot) {
                final cached = snapshot.data ?? const <Map<String, dynamic>>[];
                if (cached.isEmpty) {
                  return ErrorState(
                    message: 'Could not load. Check your connection.',
                    onRetry: () => refetch?.call(),
                  );
                }
                return _buildList(
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

          if (materials.isEmpty) {
            return const EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'No materials yet',
            );
          }

          final normalizedMaterials = materials
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false);

          return RefreshIndicator(
            onRefresh: () async => refetch?.call(),
            child: _buildList(
              context: context,
              theme: theme,
              dark: dark,
              materials: normalizedMaterials,
              latestMaterialProgress: latestMaterialProgress,
            ),
          );
        },
      ),
    );
  }

  Widget _buildList({
    required BuildContext context,
    required ThemeData theme,
    required bool dark,
    required List<Map<String, dynamic>> materials,
    required StudyMaterialProgress? latestMaterialProgress,
    bool cachedMode = false,
  }) {
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.spMd),
      children: [
        if (cachedMode)
          const _InfoBanner(
            color: DesignTokens.warning,
            icon: Icons.offline_bolt_outlined,
            text: 'Showing cached materials while you are offline.',
          ),
        if (_lowDataMode)
          const _InfoBanner(
            color: DesignTokens.info,
            icon: Icons.data_saver_on_outlined,
            text: 'Low-data mode is on. Materials load lighter and heavy previews stay minimized.',
          ),
        FutureBuilder<StudyMaterialProgress?>(
          future: latestMaterialProgress != null
              ? Future<StudyMaterialProgress?>.value(latestMaterialProgress)
              : _progressStore.loadLastMaterial(),
          builder: (context, snapshot) {
            final saved = snapshot.data;
            if (saved == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.spMd),
              child: AnimatedPress(
                onTap: () => context.push('/materials/${saved.slug}/read'),
                child: Container(
                  padding: const EdgeInsets.all(DesignTokens.spMd),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5E8C8),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                    border: Border.all(color: const Color(0xFFE7D29A)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8F5A00).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _subjectIcon(saved.contentType),
                          color: const Color(0xFF8F5A00),
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Continue Studying',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF8F5A00),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              saved.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              saved.subjectName.isEmpty
                                  ? saved.progressLabel
                                  : '${saved.subjectName} • ${saved.progressLabel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: DesignTokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: DesignTokens.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        ...materials.map((m) {
          final color = _subjectColor(m['subject']?['name'] ?? '');
          return Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.spSm),
            child: AnimatedPress(
              onTap: () => context.go('/materials/${m['slug']}'),
              child: Container(
                padding: const EdgeInsets.all(DesignTokens.spMd),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
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
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                      ),
                      child: Icon(
                        _subjectIcon(m['contentType'] ?? ''),
                        color: color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m['title'] ?? '',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            m['subject']?['name'] ?? '',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: DesignTokens.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                      ),
                      child: Text(
                        m['contentType'] ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
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

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.color,
    required this.icon,
    required this.text,
  });

  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spMd),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
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
      return DesignTokens.success;
    case 'social studies':
      return DesignTokens.error;
    default:
      return DesignTokens.accent;
  }
}

IconData _subjectIcon(String type) {
  switch (type) {
    case 'pdf':
      return Icons.picture_as_pdf;
    case 'video':
      return Icons.play_circle;
    case 'text':
      return Icons.article;
    case 'image':
      return Icons.image;
    default:
      return Icons.description;
  }
}
