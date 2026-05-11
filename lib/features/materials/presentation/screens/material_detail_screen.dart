import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/config/theme/app_colors.dart';

class MaterialDetailScreen extends StatelessWidget {
  final String slug;
  const MaterialDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(document: gql(kMaterial), variables: {'slug': slug}),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final m = result.data?['material'];
        if (m == null) return const Scaffold(body: Center(child: Text('Material not found.')));

        return Scaffold(
          appBar: AppBar(
            title: Text(m['title'], overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                icon: Icon(m['isBookmarked'] == true ? Icons.bookmark : Icons.bookmark_outline),
                onPressed: () {},
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject chip
                Chip(label: Text(m['subject']?['name'] ?? ''), backgroundColor: AppColors.primary.withOpacity(0.1)),
                const SizedBox(height: 12),

                // Description
                if (m['description'] != null && m['description'].isNotEmpty)
                  Text(m['description'], style: Theme.of(context).textTheme.bodyMedium),

                const SizedBox(height: 16),

                // YouTube embed placeholder
                if (m['youtubeEmbedUrl'] != null)
                  Container(
                    height: 200,
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                    child: const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 64)),
                  ),

                // File download
                if (m['fileUrl'] != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download),
                    label: const Text('Download PDF'),
                  ),
                ],

                const SizedBox(height: 24),

                // AI Actions
                Text('AI Tools', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _AiActionButton(label: 'Summary', icon: Icons.summarize, cost: 1, onTap: () {}),
                    const SizedBox(width: 8),
                    _AiActionButton(label: 'Flashcards', icon: Icons.style, cost: 1, onTap: () {}),
                    const SizedBox(width: 8),
                    _AiActionButton(label: 'Quiz', icon: Icons.quiz, cost: 1, onTap: () {}),
                  ],
                ),

                // AI Summary
                if (m['aiSummary'] != null && m['aiSummary'].isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('AI Summary', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                    ),
                    child: Text(m['aiSummary']),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AiActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final int cost;
  final VoidCallback onTap;
  const _AiActionButton({required this.label, required this.icon, required this.cost, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text('$label\n−$cost 💎', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
      ),
    );
  }
}
