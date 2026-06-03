import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

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
