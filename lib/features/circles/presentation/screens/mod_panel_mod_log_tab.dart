import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../../core/graphql/queries/domain/community_queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/error_state.dart';

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
                          (e as Map<String, dynamic>)['action'] as String? ?? '';
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
        return Icons.delete_outline;
      case 'remove_comment':
        return Icons.delete_sweep_outlined;
      case 'ban_user':
        return Icons.block;
      case 'unban_user':
        return Icons.person_add_alt;
      case 'mute_user':
        return Icons.volume_off_outlined;
      case 'unmute_user':
        return Icons.volume_up_outlined;
      case 'approve_post':
        return Icons.check_circle_outline;
      case 'pin_post':
        return Icons.push_pin_outlined;
      case 'lock_post':
        return Icons.lock_outline;
      case 'edit_settings':
        return Icons.settings_outlined;
      case 'add_mod':
        return Icons.admin_panel_settings_outlined;
      case 'remove_mod':
        return Icons.remove_moderator_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _colorForAction(String action) {
    switch (action) {
      case 'remove_post':
      case 'remove_comment':
      case 'ban_user':
        return DesignTokens.error;
      case 'unban_user':
      case 'unmute_user':
      case 'approve_post':
        return DesignTokens.success;
      case 'pin_post':
        return DesignTokens.warning;
      case 'lock_post':
        return DesignTokens.textSecondary;
      case 'mute_user':
        return DesignTokens.warning;
      case 'add_mod':
        return DesignTokens.primary;
      case 'remove_mod':
        return DesignTokens.error;
      default:
        return DesignTokens.textSecondary;
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
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _colorForAction(action).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(_iconForAction(action), size: 18, color: _colorForAction(action)),
      ),
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
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(createdAt),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: DesignTokens.textTertiary),
          ),
        ],
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${diff.inDays ~/ 7}w ago';
    } catch (_) {
      return '';
    }
  }
}
