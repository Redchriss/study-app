import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/services/app_preferences_service.dart';
import '../../../../core/services/material_cache_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'material_detail_body.dart';

class MaterialDetailScreen extends ConsumerStatefulWidget {
  final String slug;
  const MaterialDetailScreen({super.key, required this.slug});
  @override
  ConsumerState<MaterialDetailScreen> createState() =>
      _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends ConsumerState<MaterialDetailScreen> {
  final _preferences = AppPreferencesService();
  final _cache = MaterialCacheService();
  bool _bookmarking = false;
  String? _aiTaskLoading;
  YoutubePlayerController? _ytCtrl;
  bool _lowDataMode = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final lowDataMode = await _preferences.isLowDataMode();
    if (mounted) setState(() => _lowDataMode = lowDataMode);
  }

  @override
  void dispose() {
    _ytCtrl?.close();
    super.dispose();
  }

  Future<void> _toggleBookmark(String id, bool currentlyBookmarked) async {
    if (_bookmarking) return;
    setState(() => _bookmarking = true);
    final client = ref.read(graphqlClientProvider);
    final doc =
        currentlyBookmarked ? gql(kUnbookmarkMaterial) : gql(kBookmarkMaterial);
    try {
      final result = await client.mutate(
          MutationOptions(document: doc, variables: {'materialId': id}));
      if (!mounted) return;
      if (result.hasException) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                result.exception?.graphqlErrors.firstOrNull?.message ??
                    'Bookmark update failed'),
            backgroundColor: DesignTokens.error));
      }
    } finally {
      if (mounted) setState(() => _bookmarking = false);
    }
  }

  Future<void> _requestAiTask(
      String materialId, String taskType, dynamic refetch) async {
    if (_aiTaskLoading != null) return;
    setState(() => _aiTaskLoading = taskType);
    final client = ref.read(graphqlClientProvider);
    try {
      final result = await client.mutate(MutationOptions(
          document: gql(kRequestAiTask),
          variables: {'materialId': materialId, 'taskType': taskType}));
      if (mounted) {
        if (result.hasException) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  result.exception?.graphqlErrors.firstOrNull?.message ??
                      'AI task failed'),
              backgroundColor: DesignTokens.error));
        } else {
          refetch?.call();
        }
      }
    } finally {
      if (mounted) setState(() => _aiTaskLoading = null);
    }
  }

  bool _supportsStudyMode(Map<String, dynamic> material) {
    final contentType =
        (material['contentType'] as String? ?? '').toLowerCase();
    final fileUrl = material['fileUrl'] as String? ?? '';
    final contentText = (material['contentText'] as String? ?? '').trim();
    final youtubeEmbedUrl = material['youtubeEmbedUrl'] as String? ?? '';
    return contentType == 'pdf' ||
        fileUrl.toLowerCase().endsWith('.pdf') ||
        (contentType == 'text' && contentText.isNotEmpty) ||
        (contentType == 'video' && youtubeEmbedUrl.isNotEmpty) ||
        (contentType == 'image' && fileUrl.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Query(
      options: QueryOptions(
          document: gql(kMaterial),
          variables: {'slug': widget.slug},
          fetchPolicy: FetchPolicy.cacheAndNetwork),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading && result.data == null)
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        final live = result.data?['material'];
        if (live is Map) {
          _cache.saveMaterial(widget.slug, Map<String, dynamic>.from(live));
        }
        if (result.hasException && live == null) {
          return FutureBuilder<Map<String, dynamic>?>(
            future: _cache.loadMaterial(widget.slug),
            builder: (context, snapshot) {
              final cached = snapshot.data;
              if (cached == null)
                return Scaffold(
                  body: ErrorState(
                    message: 'Material not found.',
                    onRetry: () => refetch?.call(),
                  ),
                );
              return _buildBody(theme, cached, refetch, offline: true);
            },
          );
        }
        if (live is! Map)
          return const Scaffold(
              body: Center(child: Text('Material not found.')));
        return _buildBody(theme, Map<String, dynamic>.from(live), refetch);
      },
    );
  }

  Widget _buildBody(ThemeData theme, Map<String, dynamic> m, dynamic refetch,
      {bool offline = false}) {
    final materialId = m['id'] as String? ?? '';
    final isBookmarked = m['isBookmarked'] == true;
    final supportsStudyMode = _supportsStudyMode(m);
    final hasYoutube = m['youtubeEmbedUrl'] != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(m['title'] ?? '', overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: _bookmarking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                    color: isBookmarked ? DesignTokens.warning : null),
            onPressed: materialId.isNotEmpty
                ? () => _toggleBookmark(materialId, isBookmarked)
                : null,
          ),
        ],
      ),
      body: MaterialDetailBody(
        theme: theme,
        m: m,
        slug: widget.slug,
        materialId: materialId,
        offline: offline,
        lowDataMode: _lowDataMode,
        aiTaskLoading: _aiTaskLoading,
        onRequestAiTask: (taskType) =>
            _requestAiTask(materialId, taskType, refetch),
        supportsStudyMode: supportsStudyMode,
        hasYoutube: hasYoutube,
        onYoutubeControllerReady: (ctrl) {
          _ytCtrl?.close();
          _ytCtrl = ctrl;
        },
      ),
    );
  }
}
