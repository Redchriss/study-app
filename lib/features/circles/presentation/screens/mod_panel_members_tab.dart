import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ModPanelMembersTab extends ConsumerStatefulWidget {
  final String communitySlug;
  const ModPanelMembersTab({super.key, required this.communitySlug});

  @override
  ConsumerState<ModPanelMembersTab> createState() => _ModPanelMembersTabState();
}

class _ModPanelMembersTabState extends ConsumerState<ModPanelMembersTab> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.read(graphqlClientProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search username...',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            onSubmitted: (q) => setState(() => _searchQuery = q.trim()),
          ),
        ),
        Expanded(
          child: _searchQuery.isNotEmpty
              ? _SearchedUserActions(
                  communitySlug: widget.communitySlug,
                  username: _searchQuery,
                  client: client,
                )
              : _ModList(communitySlug: widget.communitySlug),
        ),
      ],
    );
  }
}

class _ModList extends StatelessWidget {
  final String communitySlug;
  const _ModList({required this.communitySlug});

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(kCommunityModerators),
        variables: {'slug': communitySlug},
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return const Center(child: LoadingWidget());
        final mods = (result.data?['communityModerators'] as List?) ?? [];
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Moderators',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            ),
            ...mods.map((m) {
              final user = (m as Map<String, dynamic>)['user'] as Map<String, dynamic>?;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: DesignTokens.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.shield_rounded, size: 18, color: DesignTokens.primary),
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

class _SearchedUserActions extends StatelessWidget {
  final String communitySlug;
  final String username;
  final GraphQLClient client;
  const _SearchedUserActions({
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
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        _ActionButton(
          icon: Icons.block_rounded,
          label: 'Ban user',
          color: DesignTokens.error,
          onTap: () => _banUser(context),
        ),
        _ActionButton(
          icon: Icons.check_circle_outline_rounded,
          label: 'Unban user',
          color: DesignTokens.success,
          onTap: () => _unbanUser(context),
        ),
        _ActionButton(
          icon: Icons.volume_off_rounded,
          label: 'Mute user (3 days)',
          color: DesignTokens.warning,
          onTap: () => _muteUser(context),
        ),
        _ActionButton(
          icon: Icons.admin_panel_settings_outlined,
          label: 'Add as moderator',
          color: DesignTokens.primary,
          onTap: () => _addModerator(context),
        ),
        _ActionButton(
          icon: Icons.remove_moderator_outlined,
          label: 'Remove moderator',
          color: DesignTokens.error,
          onTap: () => _removeModerator(context),
        ),
      ],
    );
  }

  Future<void> _banUser(BuildContext context) async {
    final reason = await _promptText(context, 'Ban reason');
    if (reason == null) return;
    final result = await client.mutate(MutationOptions(
      document: gql(kBanUser),
      variables: {'communitySlug': communitySlug, 'username': username, 'reason': reason},
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
    final result = await client.mutate(MutationOptions(
      document: gql(kMuteUser),
      variables: {'communitySlug': communitySlug, 'username': username, 'durationHours': 72},
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

  Future<String?> _promptText(BuildContext context, String label) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: TextField(controller: ctrl, autofocus: true, decoration: InputDecoration(hintText: label)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Confirm')),
        ],
      ),
    );
    return result?.trim().isEmpty == true ? null : result;
  }

  void _showResult(BuildContext context, QueryResult result) {
    final errors = result.hasException
        ? graphQLErrorMessage(result.exception, 'Action failed')
        : 'Action completed';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(errors),
      backgroundColor: result.hasException ? DesignTokens.error : DesignTokens.success,
    ));
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
