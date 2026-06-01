import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/widgets.dart';

const String kCommunityModerators = r'''query CommunityModerators { __typename }''';

class ModList extends StatelessWidget {
  final String communitySlug;
  const ModList({super.key, required this.communitySlug});

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
          document: gql(kCommunityModerators),
          variables: {'slug': communitySlug}),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return const Center(child: LoadingWidget());
        final mods = (result.data?['communityModerators'] as List?) ?? [];
        if (mods.isEmpty) {
          return const Center(
              child: Text('No moderators',
                  style: TextStyle(color: DesignTokens.textSecondary)));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('${mods.length} moderators',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
            ...mods.map((m) {
              final user =
                  (m as Map<String, dynamic>)['user'] as Map<String, dynamic>?;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: DesignTokens.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.shield_rounded,
                      size: 18, color: DesignTokens.primary),
                ),
                title: Text('u/${user?['username'] ?? 'unknown'}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(m['role']?.toString() ?? ''),
              );
            }),
          ],
        );
      },
    );
  }
}

class BannedList extends StatelessWidget {
  final String communitySlug;
  const BannedList({super.key, required this.communitySlug});

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
          document: gql(kBannedMembers), variables: {'slug': communitySlug}),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return const Center(child: LoadingWidget());
        final banned = (result.data?['bannedMembers'] as List?) ?? [];
        if (banned.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.block,
                  size: 48, color: DesignTokens.textTertiary),
              const SizedBox(height: 12),
              const Text('No banned members',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Search a username above to ban',
                  style: TextStyle(color: DesignTokens.textSecondary)),
            ]),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('${banned.length} banned',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
            ...banned.map((m) {
              final user =
                  (m as Map<String, dynamic>)['user'] as Map<String, dynamic>?;
              final reason = m['banReason']?.toString() ?? '';
              final expiresAt = m['banExpiresAt']?.toString();
              final isPermanent = expiresAt == null || expiresAt.isEmpty;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: DesignTokens.error.withValues(alpha: 0.1),
                  child: const Icon(Icons.block,
                      size: 18, color: DesignTokens.error),
                ),
                title: Text('u/${user?['username'] ?? 'unknown'}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  [
                    reason,
                    if (!isPermanent && expiresAt.isNotEmpty)
                      _timeUntil(expiresAt),
                  ].join(' • '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: TextButton(
                  onPressed: () =>
                      _unban(context, user?['username']?.toString()),
                  child: const Text('Unban',
                      style: TextStyle(color: DesignTokens.success)),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Future<void> _unban(BuildContext context, String? username) async {
    if (username == null) return;
    final client = GraphQLProvider.of(context).value;
    final result = await client.mutate(MutationOptions(
      document: gql(kUnbanUser),
      variables: {'communitySlug': communitySlug, 'username': username},
    ));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            result.hasException ? 'Failed to unban' : 'u/$username unbanned'),
        backgroundColor:
            result.hasException ? DesignTokens.error : DesignTokens.success,
      ));
    }
  }

  String _timeUntil(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = dt.difference(DateTime.now());
      if (diff.isNegative) return 'expired';
      if (diff.inDays > 0) return '${diff.inDays}d left';
      return '${diff.inHours}h left';
    } catch (_) {
      return '';
    }
  }
}

class MutedList extends StatelessWidget {
  final String communitySlug;
  const MutedList({super.key, required this.communitySlug});

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
          document: gql(kMutedMembers), variables: {'slug': communitySlug}),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return const Center(child: LoadingWidget());
        final muted = (result.data?['mutedMembers'] as List?) ?? [];
        if (muted.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.volume_off,
                  size: 48, color: DesignTokens.textTertiary),
              const SizedBox(height: 12),
              const Text('No muted members',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Search a username above to mute',
                  style: TextStyle(color: DesignTokens.textSecondary)),
            ]),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('${muted.length} muted',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
            ...muted.map((m) {
              final user =
                  (m as Map<String, dynamic>)['user'] as Map<String, dynamic>?;
              final expiresAt = m['muteExpiresAt']?.toString() ?? '';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: DesignTokens.warning.withValues(alpha: 0.1),
                  child: const Icon(Icons.volume_off,
                      size: 18, color: DesignTokens.warning),
                ),
                title: Text('u/${user?['username'] ?? 'unknown'}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: expiresAt.isNotEmpty
                    ? Text('Expires ${_timeUntil(expiresAt)}',
                        style: const TextStyle(
                            color: DesignTokens.textSecondary, fontSize: 12))
                    : null,
                trailing: TextButton(
                  onPressed: () =>
                      _unmute(context, user?['username']?.toString()),
                  child: const Text('Unmute',
                      style: TextStyle(color: DesignTokens.success)),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Future<void> _unmute(BuildContext context, String? username) async {
    if (username == null) return;
    final client = GraphQLProvider.of(context).value;
    final result = await client.mutate(MutationOptions(
      document: gql(kUnmuteUser),
      variables: {'communitySlug': communitySlug, 'username': username},
    ));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            result.hasException ? 'Failed to unmute' : 'u/$username unmuted'),
        backgroundColor:
            result.hasException ? DesignTokens.error : DesignTokens.success,
      ));
    }
  }

  String _timeUntil(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = dt.difference(DateTime.now());
      if (diff.isNegative) return 'expired';
      if (diff.inDays > 0) return '${diff.inDays}d left';
      return '${diff.inHours}h left';
    } catch (_) {
      return '';
    }
  }
}

class ApprovedList extends StatelessWidget {
  final String communitySlug;
  const ApprovedList({super.key, required this.communitySlug});

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
          document: gql(kApprovedUsers), variables: {'slug': communitySlug}),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return const Center(child: LoadingWidget());
        final approved = (result.data?['approvedUsers'] as List?) ?? [];
        if (approved.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_circle_outline,
                  size: 48, color: DesignTokens.textTertiary),
              const SizedBox(height: 12),
              const Text('No approved users',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Approved users can post in restricted communities',
                  style: TextStyle(color: DesignTokens.textSecondary)),
            ]),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('${approved.length} approved',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
            ...approved.map((m) {
              final user =
                  (m as Map<String, dynamic>)['user'] as Map<String, dynamic>?;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: DesignTokens.success.withValues(alpha: 0.1),
                  child: const Icon(Icons.check_circle_outline,
                      size: 18, color: DesignTokens.success),
                ),
                title: Text('u/${user?['username'] ?? 'unknown'}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              );
            }),
          ],
        );
      },
    );
  }
}

class SearchedUserActions extends StatelessWidget {
  final String communitySlug;
  final String username;
  final GraphQLClient client;
  const SearchedUserActions({
    super.key,
    required this.communitySlug,
    required this.username,
    required this.client,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Actions for u/$username',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        ActionButton(
            icon: Icons.block_rounded,
            label: 'Ban user',
            color: DesignTokens.error,
            onTap: () => _banUser(context)),
        ActionButton(
            icon: Icons.check_circle_outline_rounded,
            label: 'Unban user',
            color: DesignTokens.success,
            onTap: () => _unbanUser(context)),
        ActionButton(
            icon: Icons.volume_off_rounded,
            label: 'Mute user',
            color: DesignTokens.warning,
            onTap: () => _muteUser(context)),
        ActionButton(
            icon: Icons.volume_up_rounded,
            label: 'Unmute user',
            color: DesignTokens.success,
            onTap: () => _unmuteUser(context)),
        ActionButton(
            icon: Icons.admin_panel_settings_outlined,
            label: 'Add as moderator',
            color: DesignTokens.primary,
            onTap: () => _addModerator(context)),
        ActionButton(
            icon: Icons.remove_moderator_outlined,
            label: 'Remove moderator',
            color: DesignTokens.error,
            onTap: () => _removeModerator(context)),
      ],
    );
  }

  Future<void> _banUser(BuildContext context) async {
    final reasonCtrl = TextEditingController();
    final isPermanent = ValueNotifier<bool>(true);
    final durationDays = ValueNotifier<int>(7);

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ban u/$username'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: reasonCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Ban reason',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<bool>(
              valueListenable: isPermanent,
              builder: (_, perm, __) => SwitchListTile(
                title: const Text('Permanent'),
                value: perm,
                onChanged: (v) => isPermanent.value = v,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (!isPermanent.value)
              ValueListenableBuilder<int>(
                valueListenable: durationDays,
                builder: (_, days, __) => Wrap(
                  spacing: 6,
                  children: [3, 7, 14, 30].map((d) {
                    final sel = days == d;
                    return ChoiceChip(
                      label: Text('$d days'),
                      selected: sel,
                      onSelected: (_) => durationDays.value = d,
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm Ban')),
        ],
      ),
    );
    if (proceed != true || reasonCtrl.text.trim().isEmpty) return;

    final result = await client.mutate(MutationOptions(
      document: gql(kBanUser),
      variables: {
        'communitySlug': communitySlug,
        'username': username,
        'reason': reasonCtrl.text.trim(),
        'isPermanent': isPermanent.value,
        if (!isPermanent.value) 'durationDays': durationDays.value,
      },
    ));
    if (context.mounted) _showResult(context, result);
  }

  Future<void> _unbanUser(BuildContext context) async {
    final result = await client.mutate(MutationOptions(
      document: gql(kUnbanUser),
      variables: {'communitySlug': communitySlug, 'username': username},
    ));
    if (context.mounted) _showResult(context, result);
  }

  Future<void> _muteUser(BuildContext context) async {
    final durationDays = ValueNotifier<int>(7);
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Mute u/$username'),
        content: ValueListenableBuilder<int>(
          valueListenable: durationDays,
          builder: (_, days, __) => Wrap(
            spacing: 6,
            children: [3, 7, 14, 28].map((d) {
              final sel = days == d;
              return ChoiceChip(
                label: Text('$d days'),
                selected: sel,
                onSelected: (_) => durationDays.value = d,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Mute')),
        ],
      ),
    );
    if (proceed != true) return;

    final result = await client.mutate(MutationOptions(
      document: gql(kMuteUser),
      variables: {
        'communitySlug': communitySlug,
        'username': username,
        'durationDays': durationDays.value,
      },
    ));
    if (context.mounted) _showResult(context, result);
  }

  Future<void> _unmuteUser(BuildContext context) async {
    final result = await client.mutate(MutationOptions(
      document: gql(kUnmuteUser),
      variables: {'communitySlug': communitySlug, 'username': username},
    ));
    if (context.mounted) _showResult(context, result);
  }

  Future<void> _addModerator(BuildContext context) async {
    final result = await client.mutate(MutationOptions(
      document: gql(kAddModerator),
      variables: {'slug': communitySlug, 'username': username},
    ));
    if (context.mounted) _showResult(context, result);
  }

  Future<void> _removeModerator(BuildContext context) async {
    final result = await client.mutate(MutationOptions(
      document: gql(kRemoveModerator),
      variables: {'slug': communitySlug, 'username': username},
    ));
    if (context.mounted) _showResult(context, result);
  }

  void _showResult(BuildContext context, QueryResult result) {
    final errors = result.hasException
        ? graphQLErrorMessage(result.exception, 'Action failed')
        : 'Action completed';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(errors),
      backgroundColor:
          result.hasException ? DesignTokens.error : DesignTokens.success,
    ));
  }
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label,
            style: TextStyle(fontWeight: FontWeight.w600, color: color)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
