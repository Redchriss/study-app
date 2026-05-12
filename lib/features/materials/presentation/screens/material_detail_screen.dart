import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class MaterialDetailScreen extends StatelessWidget {
  final String slug;
  const MaterialDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Query(
      options: QueryOptions(document: gql(kMaterial), variables: {'slug': slug}),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final m = result.data?['material'];
        if (m == null) return const Scaffold(body: Center(child: Text('Material not found.')));
        return Scaffold(
          appBar: AppBar(
            title: Text(m['title'] ?? '', overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                icon: Icon(m['isBookmarked'] == true ? Icons.bookmark : Icons.bookmark_outline,
                  color: m['isBookmarked'] == true ? DesignTokens.warning : null),
                onPressed: () {},
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
                  onTap: () {},
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
                const Row(children: [
                  _AiBtn(label: 'Summary', icon: Icons.summarize, cost: 1),
                  SizedBox(width: DesignTokens.spXs),
                  _AiBtn(label: 'Flashcards', icon: Icons.style, cost: 1),
                  SizedBox(width: DesignTokens.spXs),
                  _AiBtn(label: 'Quiz', icon: Icons.quiz, cost: 1),
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
  const _AiBtn({required this.label, required this.icon, required this.cost});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedPress(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.spSm),
          decoration: BoxDecoration(
            color: DesignTokens.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(color: DesignTokens.primary.withValues(alpha: 0.15)),
          ),
          child: Column(children: [
            Icon(icon, color: DesignTokens.primary, size: 20),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DesignTokens.primary)),
            Text('−$cost 💎', style: const TextStyle(fontSize: 10, color: DesignTokens.textTertiary)),
          ]),
        ),
      ),
    );
  }
}
