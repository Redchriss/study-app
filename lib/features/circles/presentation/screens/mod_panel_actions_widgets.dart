import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import 'mod_panel_ban_widgets.dart';

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
