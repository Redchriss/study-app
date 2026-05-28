import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../../core/graphql/queries/domain/community_queries.dart';
import '../../../../core/widgets/error_state.dart';

final _actionFilters = [
  'All',
  'Remove',
  'Approve',
  'Pin',
  'Lock',
  'Ban',
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
        // Filter row
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

              // Apply local filter
              final filtered = _filter == 'All'
                  ? entries
                  : entries.where((e) {
                      final action =
                          (e as Map<String, dynamic>)['action'] as String? ??
                              '';
                      return action
                          .toLowerCase()
                          .contains(_filter.toLowerCase());
                    }).toList();

              if (filtered.isEmpty) {
                return ListView(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                    const Center(
                      child: Column(
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No moderation actions yet',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey)),
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
                    return _ModLogTile(entry: e);
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

class _ModLogTile extends StatelessWidget {
  final Map<String, dynamic> entry;

  const _ModLogTile({required this.entry});

  IconData _iconForAction(String action) {
    switch (action) {
      case 'remove_post':
      case 'remove_comment':
        return Icons.delete_outline;
      case 'ban_user':
        return Icons.block;
      case 'unban_user':
        return Icons.person_add_alt;
      case 'approve_post':
        return Icons.check_circle_outline;
      case 'pin_post':
        return Icons.push_pin_outlined;
      case 'lock_post':
        return Icons.lock_outline;
      case 'add_mod':
        return Icons.admin_panel_settings_outlined;
      case 'remove_mod':
        return Icons.remove_moderator_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = entry['action'] as String? ?? '';
    final moderator = entry['moderator'] as Map<String, dynamic>?;
    final targetUser = entry['targetUser'] as Map<String, dynamic>?;
    final post = entry['post'] as Map<String, dynamic>?;
    final createdAt = entry['createdAt'] as String? ?? '';

    return ListTile(
      leading: Icon(_iconForAction(action), size: 20),
      title: Text(
        action.replaceAll('_', ' '),
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          'by u/${moderator?['username'] ?? 'unknown'}',
          if (targetUser != null) '→ u/${targetUser['username']}',
          if (post != null) 'on "${post['title']}"',
        ].join(' '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        _formatTime(createdAt),
        style:
            Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}
