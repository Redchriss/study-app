import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'inbox_notification_card.dart';

class InboxNotificationsTab extends ConsumerWidget {
  final bool onlyUnread;
  final String? notifType;
  const InboxNotificationsTab(
      {super.key, this.onlyUnread = false, this.notifType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.read(graphqlClientProvider);

    final variables = <String, dynamic>{'limit': 25};
    if (onlyUnread) variables['onlyUnread'] = true;
    if (notifType != null) variables['notifType'] = notifType;

    return Query(
      options: QueryOptions(
        document: gql(kNotifications),
        variables: variables,
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return const Center(child: LoadingWidget());
        }
        if (result.hasException) {
          return ErrorState(
            message: graphQLErrorMessage(
                result.exception, 'Could not load notifications'),
            onRetry: () => refetch?.call(),
          );
        }

        final data = result.data?['notifications'];
        final edges = (data?['edges'] as List?) ?? [];
        final items =
            edges.map((e) => e['node'] as Map<String, dynamic>).toList();

        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_rounded,
                      size: 64,
                      color: DesignTokens.textTertiary.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  const Text('All caught up!',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: DesignTokens.textSecondary)),
                  const SizedBox(height: 8),
                  Text(
                      onlyUnread
                          ? 'No unread notifications'
                          : 'No notifications yet',
                      style: const TextStyle(color: DesignTokens.textTertiary)),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => refetch?.call(),
          child: Column(
            children: [
              // Mark all read button
              if (!onlyUnread)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () async {
                          await client.mutate(MutationOptions(
                            document: gql(kMarkAllNotificationsRead),
                          ));
                          refetch?.call();
                        },
                        icon: const Icon(Icons.done_all_rounded, size: 16),
                        label: const Text('Mark all read',
                            style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          foregroundColor: DesignTokens.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (scroll) {
                    if (scroll is ScrollEndNotification &&
                        scroll.metrics.pixels >=
                            scroll.metrics.maxScrollExtent - 200) {
                      final pageInfo = data?['pageInfo'];
                      if (pageInfo?['hasNextPage'] == true) {
                        fetchMore?.call(FetchMoreOptions(
                          variables: {'after': pageInfo['endCursor']},
                          updateQuery: (prev, next) {
                            if (next?['notifications'] == null) return prev;
                            final merged =
                                Map<String, dynamic>.from(prev ?? {});
                            final prevData = Map<String, dynamic>.from(
                                prev?['notifications'] ?? {});
                            final nextData = Map<String, dynamic>.from(
                                next!['notifications']);
                            final prevEdges =
                                (prevData['edges'] as List?) ?? [];
                            final nextEdges =
                                (nextData['edges'] as List?) ?? [];
                            merged['notifications'] = {
                              ...nextData,
                              'edges': [...prevEdges, ...nextEdges],
                            };
                            return merged;
                          },
                        ));
                      }
                    }
                    return false;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    itemCount: items.length,
                    itemBuilder: (_, i) => InboxNotificationCard(
                      notification: items[i],
                      onMarkRead: () async {
                        final nid = items[i]['id'].toString();
                        await client.mutate(MutationOptions(
                          document: gql(kMarkNotificationRead),
                          variables: {'notificationId': nid},
                        ));
                        refetch?.call();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
