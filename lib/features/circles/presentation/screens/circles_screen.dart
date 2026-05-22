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
        title: Text('Study Circles',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Query(
        options: QueryOptions(document: gql(kMyCircles)),
        builder: (result, {fetchMore, refetch}) {
          final circles = (result.data?['myCircles'] as List?) ?? [];

          if (result.isLoading && circles.isEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.all(DesignTokens.spLg),
              itemCount: 6,
              itemBuilder: (_, __) => const Padding(
                padding: EdgeInsets.only(bottom: DesignTokens.spMd),
                child: ShimmerBox(height: 100, radius: DesignTokens.radiusLg),
              ),
            );
          }

          if (result.hasException && circles.isEmpty) {
            return ErrorState(
                message: 'Could not load. Check your connection.',
                onRetry: () => refetch?.call());
          }

          if (circles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: DesignTokens.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.groups_rounded,
                        size: 64, color: DesignTokens.primary),
                  ),
                  const SizedBox(height: 24),
                  Text('No circles yet',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    'Complete your profile setup to join\nstudy groups matching your level.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: DesignTokens.textSecondary,
                        height: 1.4,
                        fontSize: 15),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () => context.push('/profile/edit'),
                    icon: const Icon(Icons.person_outline),
                    label: const Text('Complete Profile'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => refetch?.call(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(DesignTokens.spLg,
                  DesignTokens.spSm, DesignTokens.spLg, DesignTokens.spXl),
              itemCount: circles.length,
              itemBuilder: (_, i) {
                final c = circles[i];
                final String level =
                    c['educationLevel']?.toString().toLowerCase() ?? '';
                final isTertiary = level == 'tertiary';
                final isPrimary = level == 'primary';

                final Color accentColor = isTertiary
                    ? const Color(0xFF5A6BB2)
                    : isPrimary
                        ? const Color(0xFFE87E5E)
                        : const Color(0xFF389E75);

                final IconData levelIcon = isTertiary
                    ? Icons.account_balance_rounded
                    : isPrimary
                        ? Icons.child_care_rounded
                        : Icons.menu_book_rounded;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AnimatedPress(
                    onTap: () => context.push('/circles/${c['slug']}'),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: dark ? DesignTokens.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  accentColor.withValues(alpha: 0.8),
                                  accentColor
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child:
                                Icon(levelIcon, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c['name'] ?? '',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            accentColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        c['educationLevel'] ?? '',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: accentColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '•',
                                      style: TextStyle(
                                          color: DesignTokens.textTertiary,
                                          fontSize: 12),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(Icons.people_alt_rounded,
                                        size: 14,
                                        color: DesignTokens.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${c['memberCount'] ?? 0}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: DesignTokens.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right_rounded,
                              color: DesignTokens.textTertiary),
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
}
