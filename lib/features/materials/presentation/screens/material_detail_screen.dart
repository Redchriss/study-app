import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
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

  Future<void> _toggleBookmark(String id, bool currentlyBookmarked) async {
    if (_bookmarking) return;
    setState(() => _bookmarking = true);
    final client = ref.read(graphqlClientProvider);
    final doc = currentlyBookmarked ? gql(kUnbookmarkMaterial) : gql(kBookmarkMaterial);
    await client.mutate(MutationOptions(document: doc, variables: {'materialId': id}));
    setState(() => _bookmarking = false);
  }

  Future<void> _requestAiTask(String materialId, String taskType, dynamic refetch) async {
    if (_aiTaskLoading != null) return;
    setState(() => _aiTaskLoading = taskType);
    final client = ref.read(graphqlClientProvider);
    final result = await client.mutate(MutationOptions(
      document: gql(kRequestAiTask),
      variables: {'materialId': materialId, 'taskType': taskType},
    ));
    if (mounted) {
      if (result.hasException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.exception?.graphqlErrors.first.message ?? 'AI task failed'), backgroundColor: DesignTokens.error),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${taskType} generated!'), backgroundColor: DesignTokens.success),
        );
        refetch?.call();
      }
      setState(() => _aiTaskLoading = null);
    }
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

              if (m['youtubeEmbedUrl'] != null)
                GlassCard(child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                  child: const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 64)),
                )),

              if (m['fileUrl'] != null) ...[
                const SizedBox(height: DesignTokens.spSm),
                AnimatedPress(
                  onTap: () async {
                    final url = m['fileUrl'] as String?;
                    if (url != null && await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
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
                  _AiBtn(label: 'Summary', icon: Icons.summarize, cost: 1,
                    loading: _aiTaskLoading == 'summary',
                    onTap: materialId.isNotEmpty ? () => _requestAiTask(materialId, 'summary', refetch) : null),
                  const SizedBox(width: DesignTokens.spXs),
                  _AiBtn(label: 'Flashcards', icon: Icons.style, cost: 1,
                    loading: _aiTaskLoading == 'flashcards',
                    onTap: materialId.isNotEmpty ? () => _requestAiTask(materialId, 'flashcards', refetch) : null),
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
