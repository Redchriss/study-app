import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/services/download_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class MaterialDetailScreen extends ConsumerStatefulWidget {
  final String slug;
  const MaterialDetailScreen({super.key, required this.slug});

  @override
  ConsumerState<MaterialDetailScreen> createState() => _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends ConsumerState<MaterialDetailScreen> {
  bool _bookmarking = false;
  String? _aiTaskLoading;
  YoutubePlayerController? _ytCtrl;

  @override
  void dispose() {
    _ytCtrl?.close();
    super.dispose();
  }

  Future<void> _toggleBookmark(String id, bool currentlyBookmarked) async {
    if (_bookmarking) return;
    setState(() => _bookmarking = true);
    final client = ref.read(graphqlClientProvider);
    final doc = currentlyBookmarked ? gql(kUnbookmarkMaterial) : gql(kBookmarkMaterial);
    try {
      final result = await client.mutate(MutationOptions(document: doc, variables: {'materialId': id}));
      if (!mounted) return;
      if (result.hasException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.exception?.graphqlErrors.firstOrNull?.message ?? 'Bookmark update failed'),
            backgroundColor: DesignTokens.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _bookmarking = false);
      }
    }
  }

  Future<void> _requestAiTask(String materialId, String taskType, dynamic refetch) async {
    if (_aiTaskLoading != null) return;
    setState(() => _aiTaskLoading = taskType);
    final client = ref.read(graphqlClientProvider);
    try {
      final result = await client.mutate(MutationOptions(
        document: gql(kRequestAiTask),
        variables: {'materialId': materialId, 'taskType': taskType},
      ));
      if (mounted) {
        if (result.hasException) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.exception?.graphqlErrors.firstOrNull?.message ?? 'AI task failed'),
              backgroundColor: DesignTokens.error,
            ),
          );
        } else {
          refetch?.call();
        }
      }
    } finally {
      if (mounted) {
        setState(() => _aiTaskLoading = null);
      }
    }
  }

  bool _supportsStudyMode(Map<String, dynamic> material) {
    final contentType = (material['contentType'] as String? ?? '').toLowerCase();
    final fileUrl = material['fileUrl'] as String? ?? '';
    final contentText = (material['contentText'] as String? ?? '').trim();
    final hasPdf = contentType == 'pdf' || fileUrl.toLowerCase().endsWith('.pdf');
    final hasText = contentType == 'text' && contentText.isNotEmpty;
    return hasPdf || hasText;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Query(
      options: QueryOptions(document: gql(kMaterial), variables: {'slug': widget.slug}),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final m = result.data?['material'];
        if (m == null) return const Scaffold(body: Center(child: Text('Material not found.')));
        final materialId = m['id'] as String? ?? '';
        final isBookmarked = m['isBookmarked'] == true;
        final supportsStudyMode = _supportsStudyMode(m);
        return Scaffold(
          appBar: AppBar(
            title: Text(m['title'] ?? '', overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                icon: _bookmarking
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                    color: isBookmarked ? DesignTokens.warning : null),
                onPressed: materialId.isNotEmpty ? () => _toggleBookmark(materialId, isBookmarked) : null,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.spMd),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: DesignTokens.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(m['subject']?['name'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DesignTokens.primary)),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: DesignTokens.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(m['contentType'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DesignTokens.accent)),
                  ),
                ]),
                if (m['description'] != null && m['description'].toString().isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.spMd),
                  Text(m['description'], style: theme.textTheme.bodyMedium),
                ],
              ])),

              const SizedBox(height: DesignTokens.spMd),

              if (supportsStudyMode) ...[
                AnimatedPress(
                  onTap: () => context.push('/materials/${widget.slug}/read'),
                  child: GlassCard(
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: DesignTokens.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.chrome_reader_mode_rounded, color: DesignTokens.success, size: 24),
                        ),
                        const SizedBox(width: DesignTokens.spMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Study now',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Open this material in a focused reader and continue where you left off.',
                                style: TextStyle(fontSize: 12, color: DesignTokens.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: DesignTokens.textTertiary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.spMd),
              ],

              if (m['youtubeEmbedUrl'] != null)
                _YoutubeInlinePlayer(
                  url: m['youtubeEmbedUrl'] as String? ?? '',
                  onControllerReady: (ctrl) {
                    _ytCtrl?.close();
                    _ytCtrl = ctrl;
                  },
                ),

              if (m['fileUrl'] != null) ...[
                const SizedBox(height: DesignTokens.spSm),
                AnimatedPress(
                  onTap: () async {
                    final url = m['fileUrl'] as String?;
                    final name = m['title'] as String? ?? 'download';
                    if (url == null) return;
                    final fname = '${name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}.pdf';
                    final path = await DownloadService.downloadFile(url, fname);
                    if (path != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Saved to Downloads/Yaza/'), backgroundColor: DesignTokens.success),
                      );
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Download failed. Try again.'), backgroundColor: DesignTokens.error),
                      );
                    }
                  },
                  child: GlassCard(child: Row(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: DesignTokens.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.download, color: DesignTokens.primary, size: 22),
                    ),
                    const SizedBox(width: DesignTokens.spSm),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Download', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      Text(('${m['contentType'] ?? ''} file').toUpperCase(), style: const TextStyle(fontSize: 11, color: DesignTokens.textTertiary)),
                    ]),
                  ])),
                ),
              ],

              const SizedBox(height: DesignTokens.spMd),

              GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('AI Tools', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: DesignTokens.spSm),
                Row(children: [
                  _AiBtn(label: 'Flashcards', icon: Icons.style, cost: 1,
                    loading: _aiTaskLoading == 'flashcards',
                    onTap: materialId.isNotEmpty ? () => _requestAiTask(materialId, 'flashcards', refetch) : null),
                  const SizedBox(width: DesignTokens.spXs),
                  _AiBtn(label: 'Summary', icon: Icons.summarize, cost: 1,
                    loading: _aiTaskLoading == 'summary',
                    onTap: materialId.isNotEmpty ? () => _requestAiTask(materialId, 'summary', refetch) : null),
                  const SizedBox(width: DesignTokens.spXs),
                  _AiBtn(label: 'Quiz', icon: Icons.quiz, cost: 1,
                    loading: _aiTaskLoading == 'quiz',
                    onTap: materialId.isNotEmpty ? () => _requestAiTask(materialId, 'quiz', refetch) : null),
                ]),
              ])),

              if (m['aiSummary'] != null && m['aiSummary'].toString().isNotEmpty) ...[
                const SizedBox(height: DesignTokens.spMd),
                GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.auto_awesome, size: 16, color: DesignTokens.warning),
                    const SizedBox(width: 6),
                    Text('AI Summary', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: DesignTokens.spSm),
                  Text(m['aiSummary'], style: theme.textTheme.bodyMedium),
                ])),
              ],
            ]),
          ),
      );
      },
    );
  }
}

class _YoutubeInlinePlayer extends StatefulWidget {
  final String url;
  final ValueChanged<YoutubePlayerController> onControllerReady;
  const _YoutubeInlinePlayer({required this.url, required this.onControllerReady});
  @override
  State<_YoutubeInlinePlayer> createState() => _YoutubeInlinePlayerState();
}

class _YoutubeInlinePlayerState extends State<_YoutubeInlinePlayer> {
  late final YoutubePlayerController _ctrl;

  String _extractVideoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      final fromQuery = uri.queryParameters['v'];
      if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;
      final segments = uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
      if (uri.host.contains('youtu.be') && segments.isNotEmpty) return segments.first;
      if (segments.length >= 2 && segments.first == 'embed') return segments[1];
      if (segments.isNotEmpty) return segments.last;
    }
    final parts = url.split('/');
    return parts.last.split('?').first;
  }

  @override
  void initState() {
    super.initState();
    _ctrl = YoutubePlayerController.fromVideoId(
      videoId: _extractVideoId(widget.url),
      autoPlay: false,
      params: const YoutubePlayerParams(showFullscreenButton: true),
    );
    widget.onControllerReady(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: YoutubePlayer(controller: _ctrl, aspectRatio: 16 / 9),
      ),
    );
  }
}

class _AiBtn extends StatelessWidget {
  final String label; final IconData icon; final int cost;
  final bool loading; final VoidCallback? onTap;
  const _AiBtn({required this.label, required this.icon, required this.cost, this.loading = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedPress(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.spSm),
          decoration: BoxDecoration(
            color: DesignTokens.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(color: DesignTokens.primary.withValues(alpha: 0.15)),
          ),
          child: Column(children: [
            loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(icon, color: DesignTokens.primary, size: 20),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DesignTokens.primary)),
            Text('−$cost 💎', style: const TextStyle(fontSize: 10, color: DesignTokens.textTertiary)),
          ]),
        ),
      ),
    );
  }
}
