import '../../../../core/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../../core/graphql/queries/domain/community_queries.dart';
import '../../../../core/widgets/error_state.dart';
import 'mod_log_tile.dart';

final _actionFilters = [
  'All',
  'Remove post',
  'Remove comment',
  'Ban user',
  'Unban user',
  'Mute user',
  'Unmute user',
  'Approve post',
  'Pin post',
  'Lock post',
];

class ModPanelModLogTab extends ConsumerStatefulWidget {
  final String communitySlug;

  const ModPanelModLogTab({super.key, required this.communitySlug});

  @override
  ConsumerState<ModPanelModLogTab> createState() => _ModPanelModLogTabState();
}

class _ModPanelModLogTabState extends ConsumerState<ModPanelModLogTab> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _actionFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final f = _actionFilters[i];
                final selected = _filter == f;
                return ChoiceChip(
                  label: Text(f,
                      style: TextStyle(
                          fontSize: 12,
                          color: selected ? Colors.white : Colors.grey)),
                  selected: selected,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  onSelected: (_) => setState(() => _filter = f),
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),
        ),
        Expanded(
          child: Query(
            options: QueryOptions(
              document: gql(kModLogQuery),
              variables: {'communitySlug': widget.communitySlug},
              fetchPolicy: FetchPolicy.networkOnly,
            ),
            builder: (result, {fetchMore, refetch}) {
              if (result.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (result.hasException) {
                return ErrorState(
                  message: result.exception?.graphqlErrors.first.message ??
                      'Failed to load mod log',
                  onRetry: () => refetch?.call(),
                );
              }
              final entries = result.data?['modLog'] as List<dynamic>? ?? [];

              final filtered = _filter == 'All'
                  ? entries
                  : entries.where((e) {
                      final action =
                          (e as Map<String, dynamic>)['action'] as String? ??
                              '';
                      final filterKey =
                          _filter.toLowerCase().replaceAll(' ', '_');
                      return action == filterKey;
                    }).toList();

              if (filtered.isEmpty) {
                return ListView(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                    const Center(
                      child: Column(
                        children: [
                          Icon(Icons.history, size: 64, color: DesignTokens.textTertiary),
                          SizedBox(height: 16),
                          Text('No moderation actions yet',
                              style:
                                  TextStyle(fontSize: 18, color: DesignTokens.textTertiary)),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return RefreshIndicator(
                onRefresh: () async => refetch?.call(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final e = filtered[i] as Map<String, dynamic>;
                    return ModLogTile(entry: e);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
