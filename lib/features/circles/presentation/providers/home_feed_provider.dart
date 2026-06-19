import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/circles_domain.dart';
import 'circles_providers.dart';

/// Paginated home-feed state backed by [CirclesRepository]. This is the
/// reference pattern for migrating Circles list screens off inline
/// `graphql_flutter` `Query` widgets onto the typed data layer.
///
/// The family argument is the feed sort (e.g. `BEST`, `HOT`, `NEW`), or null
/// for the backend default.
class HomeFeedNotifier
    extends FamilyAsyncNotifier<CirclePage<CirclePost>, String?> {
  bool _loadingMore = false;

  @override
  Future<CirclePage<CirclePost>> build(String? arg) {
    return ref.read(circlesRepositoryProvider).homeFeed(sort: arg);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(circlesRepositoryProvider).homeFeed(sort: arg),
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasNextPage || _loadingMore) return;
    _loadingMore = true;
    try {
      final next = await ref
          .read(circlesRepositoryProvider)
          .homeFeed(sort: arg, after: current.endCursor);
      state = AsyncData(current.merge(next));
    } catch (error, stackTrace) {
      state = AsyncError<CirclePage<CirclePost>>(error, stackTrace)
          .copyWithPrevious(state);
    } finally {
      _loadingMore = false;
    }
  }
}

final homeFeedProvider = AsyncNotifierProvider.family<HomeFeedNotifier,
    CirclePage<CirclePost>, String?>(HomeFeedNotifier.new);
