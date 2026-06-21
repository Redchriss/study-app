import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/unread_count_provider.dart';
import 'inbox_notification_card.dart';

class InboxNotificationsTab extends ConsumerStatefulWidget {
  final bool onlyUnread;
  final String? notifType;
  const InboxNotificationsTab({
    super.key,
    this.onlyUnread = false,
    this.notifType,
  });

  @override
  ConsumerState<InboxNotificationsTab> createState() =>
      _InboxNotificationsTabState();
}

class _InboxNotificationsTabState extends ConsumerState<InboxNotificationsTab> {

  @override
  Widget build(BuildContext context) {
    final client = ref.read(graphqlClientProvider);

    // Backend returns a flat list; unreadOnly filters on the server side.
    final variables = <String, dynamic>{'unreadOnly': widget.onlyUnread};

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

        // Flat list from backend
        final items = (result.data?['notifications'] as List?) ??
            <Map<String, dynamic>>[];

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
                  Text(
                    widget.onlyUnread
                        ? 'No unread notifications'
                        : 'All caught up!',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: DesignTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.onlyUnread
                        ? 'You have no unread notifications'
                        : 'When someone replies, mentions you, or sends a modmail, it will show up here.',
                    style: const TextStyle(color: DesignTokens.textTertiary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => refetch?.call(),
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            itemCount: items.length + (_loadingMore ? 1 : 0),
            itemBuilder: (_, i) {
              if (i >= items.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child:
                      Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              final n = items[i];
              return InboxNotificationCard(
                notification: n,
                onMarkRead: () async {
                  final nid = n['id'].toString();
                  await client.mutate(MutationOptions(
                    document: gql(kMarkNotificationRead),
                    variables: {'notificationId': nid},
                  ));
                  ref.read(unreadCountProvider.notifier).decrement();
                  refetch?.call();
                },
              );
            },
          ),
        );
      },
    );
  }
}
