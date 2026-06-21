import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class CommunitySidebarScreen extends ConsumerWidget {
  final String slug;
  const CommunitySidebarScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Query(
      options: QueryOptions(
        document: gql(r'''
          query CommunitySidebar($slug: String!) {
            community(slug: $slug) {
              id slug name displayName description sidebarMarkdown
              memberCount postCount createdAt communityType
            }
            communityModerators(slug: $slug) { id role user { username } }
            communityRules(slug: $slug) { id title description order }
          }
        '''),
        variables: {'slug': slug},
      ),
      builder: (QueryResult result,
          {VoidCallback? refetch, FetchMore? fetchMore}) {
        if (result.isLoading)
          return Scaffold(
              appBar: AppBar(), body: const Center(child: LoadingWidget()));
        final c = result.data?['community'] as Map<String, dynamic>?;
        if (c == null)
          return Scaffold(
              appBar: AppBar(), body: const Center(child: Text('Not found')));
        final rules = (result.data?['communityRules'] as List?) ?? [];
        final mods = (result.data?['communityModerators'] as List?) ?? [];
        final createdAt = c['createdAt']?.toString();
        final createdDate = createdAt != null
            ? DateFormat.yMMMMd().format(DateTime.tryParse(createdAt) ?? DateTime.now())
            : null;

        return Scaffold(
          appBar: AppBar(
            title: Text('y/${c['name']}',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(c['displayName']?.toString() ?? '',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('y/${c['name']}',
                  style: const TextStyle(color: DesignTokens.textSecondary)),
              const SizedBox(height: 12),
              if (c['description'] != null &&
                  c['description'].toString().isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: dark
                        ? DesignTokens.darkSurfaceVariant
                        : DesignTokens.surfaceVariant,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                  child: Text(c['description'].toString(),
                      style: const TextStyle(height: 1.4, fontSize: 14)),
                ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                  border: Border.all(
                      color: (dark ? DesignTokens.darkBorder : DesignTokens.border)
                          .withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatColumn(
                      icon: Icons.people_outline_rounded,
                      value: _formatCount((c['memberCount'] as num?)?.toInt() ?? 0),
                      label: 'Members',
                      color: DesignTokens.primary,
                    ),
                    Container(width: 1, height: 36, color: DesignTokens.border),
                    _StatColumn(
                      icon: Icons.article_outlined,
                      value: _formatCount((c['postCount'] as num?)?.toInt() ?? 0),
                      label: 'Posts',
                      color: DesignTokens.accent,
                    ),
                    Container(width: 1, height: 36, color: DesignTokens.border),
                    _StatColumn(
                      icon: Icons.lock_outline,
                      value: c['communityType']?.toString() ?? 'public',
                      label: 'Type',
                      color: DesignTokens.warning,
                    ),
                  ],
                ),
              ),
              if (createdDate != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.cake_outlined,
                        size: 14, color: DesignTokens.textTertiary),
                    const SizedBox(width: 6),
                    Text('Created $createdDate',
                        style: const TextStyle(
                            fontSize: 12, color: DesignTokens.textTertiary)),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Text('Rules',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (rules.isEmpty)
                const Text('No rules yet',
                    style: TextStyle(color: DesignTokens.textSecondary))
              else
                ...rules.asMap().entries.map((e) {
                  final r = e.value as Map<String, dynamic>;
                  return _ExpandableRule(
                    index: e.key + 1,
                    title: r['title']?.toString() ?? '',
                    description: r['description']?.toString(),
                  );
                }),
              const SizedBox(height: 24),
              Text('Moderators',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: mods.map((m) {
                  final user = (m as Map<String, dynamic>)['user']
                      as Map<String, dynamic>?;
                  final username = user?['username']?.toString() ?? 'unknown';
                  return ActionChip(
                    avatar: const Icon(Icons.shield_rounded,
                        size: 14, color: DesignTokens.primary),
                    label: Text('u/$username',
                        style: const TextStyle(fontSize: 12)),
                    onPressed: () => context.push('/u/$username'),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatColumn({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: DesignTokens.textTertiary)),
      ],
    );
  }
}

class _ExpandableRule extends StatefulWidget {
  final int index;
  final String title;
  final String? description;

  const _ExpandableRule({
    required this.index,
    required this.title,
    this.description,
  });

  @override
  State<_ExpandableRule> createState() => _ExpandableRuleState();
}

class _ExpandableRuleState extends State<_ExpandableRule> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hasDescription =
        widget.description != null && widget.description!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: hasDescription
            ? () {
                HapticService.lightTap();
                setState(() => _expanded = !_expanded);
              }
            : null,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(
                color: (dark ? DesignTokens.darkBorder : DesignTokens.border)
                    .withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: DesignTokens.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text('${widget.index}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: DesignTokens.primary)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                  if (hasDescription)
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: DesignTokens.durFast,
                      child: Icon(Icons.expand_more_rounded,
                          size: 18, color: DesignTokens.textTertiary),
                    ),
                ],
              ),
              if (_expanded && hasDescription) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 34),
                  child: Text(widget.description!,
                      style: const TextStyle(
                          color: DesignTokens.textSecondary,
                          fontSize: 13,
                          height: 1.4)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
