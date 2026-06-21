import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'notification_item.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final client = ref.read(graphqlClientProvider);

    return Query(
      options: QueryOptions(
          document: gql(kNotifications),
          variables: const {'unreadOnly': false}),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return Scaffold(
            appBar: AppBar(
                title: Text('Notifications',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800))),
            body: const LoadingWidget(),
          );
        }
        if (result.hasException) {
          return Scaffold(
            appBar: AppBar(
                title: Text('Notifications',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800))),
            body: ErrorState(
              message: graphQLErrorMessage(
                  result.exception, 'Could not load notifications.'),
              onRetry: () => refetch?.call(),
            ),
          );
        }
        // Cursor-paginated response: { edges: [{ node: { id, notifType, ... } }] }
        final edges = (result.data?['notifications']?['edges'] as List?) ??
            <Map<String, dynamic>>[];
        final items = edges
            .map((e) => e['node'] as Map<String, dynamic>)
            .toList();
        final unreadCount =
            result.data?['unreadNotificationCount'] as int? ?? 0;

        return Scaffold(
          appBar: AppBar(
            title: Text('Notifications',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            actions: unreadCount > 0
                ? [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: TextButton.icon(
                        icon: const Icon(Icons.done_all_rounded, size: 18),
                        label: const Text('Mark all read'),
                        onPressed: () async {
                          final markResult = await client.mutate(
                              MutationOptions(
                                  document: gql(kMarkAllNotificationsRead)));
                          if (!context.mounted) return;
                          if (markResult.hasException) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(graphQLErrorMessage(
                                    markResult.exception,
                                    'Could not mark notifications as read.')),
                                backgroundColor: DesignTokens.error,
                              ),
                            );
                            return;
                          }
                          refetch?.call();
                        },
                      ),
                    ),
                  ]
                : null,
          ),
          body: RefreshIndicator(
            onRefresh: () async => refetch?.call(),
            child: items.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.2),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: DesignTokens.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_none_rounded,
                            size: 64, color: DesignTokens.primary),
                      ),
                      const SizedBox(height: 24),
                      Text('All caught up!',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      const Text(
                        'When you get replies, upvotes, or quiz results, they\'ll show up right here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: DesignTokens.textSecondary,
                            fontSize: 15,
                            height: 1.4),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final n = items[i];
                      final type = n['notifType'] as String? ?? '';
                      return NotificationItem(
                        notification: n,
                        isRead: n['isRead'] == true,
                        type: type,
                        icon: NotificationItem.iconForType(type),
                        color: NotificationItem.colorForType(type),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
