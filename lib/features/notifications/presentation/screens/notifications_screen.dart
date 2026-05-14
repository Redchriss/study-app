import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final client = ref.read(graphqlClientProvider);
    return Query(
      options: QueryOptions(document: gql(kNotifications), variables: const {'unreadOnly': false}),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Notifications', style: theme.textTheme.titleLarge),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (result.hasException) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Notifications', style: theme.textTheme.titleLarge),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  result.exception?.graphqlErrors.firstOrNull?.message ?? 'Could not load notifications.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        final items = (result.data?['notifications'] as List?) ?? <Map<String, dynamic>>[];
        final unreadCount = result.data?['unreadNotificationCount'] as int? ?? 0;
        return Scaffold(
          appBar: AppBar(
            title: Text('Notifications', style: theme.textTheme.titleLarge),
            actions: unreadCount > 0
              ? [IconButton(
                  icon: const Icon(Icons.done_all),
                  tooltip: 'Mark all read',
                  onPressed: () async {
                    final markResult = await client.mutate(MutationOptions(document: gql(kMarkAllNotificationsRead)));
                    if (!context.mounted) return;
                    if (markResult.hasException) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(markResult.exception?.graphqlErrors.firstOrNull?.message ?? 'Could not mark notifications as read.'),
                          backgroundColor: DesignTokens.error,
                        ),
                      );
                      return;
                    }
                    refetch?.call();
                  },
                )]
              : null,
          ),
          body: RefreshIndicator(
            onRefresh: () async => refetch?.call(),
            child: items.isEmpty
            ? ListView(children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                const EmptyState(
                  icon: Icons.notifications_none,
                  title: 'No notifications yet',
                ),
              ])
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                  itemBuilder: (_, i) {
                    final n = items[i];
                    return ListTile(
                      leading: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: n['isRead'] == true ? DesignTokens.surfaceVariant : DesignTokens.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _iconForType(n['notificationType'] as String? ?? ''),
                          color: n['isRead'] == true ? DesignTokens.textTertiary : DesignTokens.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(n['message'] ?? '', style: TextStyle(
                        fontWeight: n['isRead'] == true ? FontWeight.normal : FontWeight.w600,
                      )),
                      subtitle: Text(_timeAgo(n['createdAt'] as String? ?? ''),
                        style: const TextStyle(fontSize: 12, color: DesignTokens.textTertiary)),
                    );
                  },
                ),
          ),
        );
      },
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'reply': return Icons.reply;
      case 'upvote': return Icons.arrow_upward;
      case 'circle_invite': return Icons.group_add;
      case 'quiz_result': return Icons.quiz;
      case 'ai_credits': return Icons.auto_awesome;
      default: return Icons.notifications;
    }
  }

  String _timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${(diff.inDays / 7).floor()}w ago';
    } catch (_) {
      return '';
    }
  }
}
