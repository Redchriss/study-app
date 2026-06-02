import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final unreadCountProvider = NotifierProvider<UnreadCountNotifier, int>(
  UnreadCountNotifier.new,
);

class UnreadCountNotifier extends Notifier<int> {
  Timer? _timer;

  @override
  int build() {
    ref.onDispose(() => _timer?.cancel());
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _fetch());
    return 0;
  }

  Future<void> _fetch() async {
    try {
      final client = ref.read(graphqlClientProvider);
      final result = await client.query(QueryOptions(
        document: gql(kNotifications),
        variables: const {'limit': 1, 'onlyUnread': true},
        fetchPolicy: FetchPolicy.networkOnly,
      ));
      if (result.hasException) return;
      final count = result.data?['unreadNotificationCount'] as int? ?? 0;
      state = count;
    } catch (e) {
      debugPrint('UnreadCountNotifier._fetch failed: $e');
    }
  }

  Future<void> markRead(String notificationId) async {
    try {
      final client = ref.read(graphqlClientProvider);
      await client.mutate(MutationOptions(
        document: gql(kMarkNotificationRead),
        variables: {'notificationId': notificationId},
      ));
      state = state > 0 ? state - 1 : 0;
    } catch (e) {
      debugPrint('UnreadCountNotifier.markRead failed: $e');
    }
  }

  Future<void> markAllRead() async {
    try {
      final client = ref.read(graphqlClientProvider);
      await client.mutate(MutationOptions(
        document: gql(kMarkAllNotificationsRead),
      ));
      state = 0;
    } catch (e) {
      debugPrint('UnreadCountNotifier.markAllRead failed: $e');
    }
  }

  void decrement() {
    if (state > 0) state = state - 1;
  }

  void refresh() => _fetch();
}
