import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class MaterialsScreen extends StatelessWidget {
  const MaterialsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('Materials', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Query(
        options: QueryOptions(document: gql(kMaterials), variables: const {'limit': 50}),
        builder: (result, {fetchMore, refetch}) {
          if (result.hasException) {
          return ErrorState(message: 'Could not load. Check your connection.', onRetry: () => refetch?.call());
          }
          if (result.isLoading) {
            return _buildShimmer();
          }
          final materials = (result.data?['materials'] as List?) ?? [];
          if (materials.isEmpty) {
            return const EmptyState(icon: Icons.menu_book_outlined, title: 'No materials yet');
          }
          return RefreshIndicator(
            onRefresh: () async => refetch?.call(),
            child: ListView.builder(
              padding: const EdgeInsets.all(DesignTokens.spMd),
              itemCount: materials.length,
              itemBuilder: (_, i) {
                final m = materials[i];
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
                        border: Border.all(color: (dark ? DesignTokens.darkBorder : DesignTokens.border).withValues(alpha: 0.5)),
                        boxShadow: DesignTokens.shadowSm(dark),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(DesignTokens.radiusMd)),
                            child: Icon(_subjectIcon(m['contentType'] ?? ''), color: color, size: 22),
                          ),
                          const SizedBox(width: DesignTokens.spMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m['title'] ?? '', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(m['subject']?['name'] ?? '', style: theme.textTheme.labelSmall?.copyWith(color: DesignTokens.textTertiary)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                            ),
                            child: Text(m['contentType'] ?? '', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
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

Color _subjectColor(String name) {
  switch (name.toLowerCase()) {
    case 'english': case 'chichewa': return DesignTokens.primary;
    case 'mathematics': return DesignTokens.warning;
    case 'science': return DesignTokens.success;
    case 'social studies': return DesignTokens.error;
    default: return DesignTokens.accent;
  }
}

IconData _subjectIcon(String type) {
  switch (type) {
    case 'pdf': return Icons.picture_as_pdf;
    case 'video': return Icons.play_circle;
    case 'text': return Icons.article;
    case 'image': return Icons.image;
    default: return Icons.description;
  }
}
