import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class CirclesScreen extends StatelessWidget {
  const CirclesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('Study Circles', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Query(
        options: QueryOptions(document: gql(kMyCircles)),
        builder: (result, {fetchMore, refetch}) {
          if (result.hasException) {
          return ErrorState(message: 'Could not load. Check your connection.', onRetry: () => refetch?.call());
          }
          if (result.isLoading) {
            return ListView.builder(
              padding: const EdgeInsets.all(DesignTokens.spMd),
              itemCount: 6, itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.spSm),
                child: ShimmerBox(height: 72, radius: DesignTokens.radiusLg),
              ),
            );
          }
          final circles = (result.data?['myCircles'] as List?) ?? [];
          if (circles.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.groups_outlined, size: 80, color: DesignTokens.textTertiary.withValues(alpha: 0.5)),
              const SizedBox(height: DesignTokens.spMd),
              Text('No circles yet', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('Complete your profile setup to join', style: TextStyle(color: DesignTokens.textSecondary)),
            ]));
          }
          return RefreshIndicator(
            onRefresh: () async => refetch?.call(),
            child: ListView.builder(
              padding: const EdgeInsets.all(DesignTokens.spMd),
              itemCount: circles.length,
              itemBuilder: (_, i) {
                final c = circles[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: DesignTokens.spSm),
                  child: AnimatedPress(
                    onTap: () => context.go('/circles/${c['slug']}'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spMd, vertical: DesignTokens.spSm),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                        border: Border.all(color: (dark ? DesignTokens.darkBorder : DesignTokens.border).withValues(alpha: 0.5)),
                        boxShadow: DesignTokens.shadowSm(dark),
                      ),
                      child: Row(children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(color: DesignTokens.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(DesignTokens.radiusMd)),
                          child: const Icon(Icons.group, color: DesignTokens.primary, size: 22),
                        ),
                        const SizedBox(width: DesignTokens.spMd),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['name'] ?? '', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                            Text('${c['educationLevel'] ?? ''}  ·  ${c['memberCount'] ?? 0} members', style: theme.textTheme.labelSmall?.copyWith(color: DesignTokens.textTertiary)),
                          ],
                        )),
                        const Icon(Icons.chevron_right, color: DesignTokens.textTertiary),
                      ]),
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
}
