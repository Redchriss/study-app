import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

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
