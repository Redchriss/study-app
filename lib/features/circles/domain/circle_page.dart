import 'circle_parse.dart';

/// A generic, typed view over a GraphQL Relay-style connection
/// (`{ edges { node }, pageInfo { hasNextPage endCursor }, totalCount }`).
class CirclePage<T> {
  final List<T> items;
  final bool hasNextPage;
  final String? endCursor;
  final int totalCount;

  const CirclePage({
    required this.items,
    required this.hasNextPage,
    required this.endCursor,
    required this.totalCount,
  });

  const CirclePage.empty()
      : items = const [],
        hasNextPage = false,
        endCursor = null,
        totalCount = 0;

  /// Builds a page from a connection map, parsing each `node` via [parse].
  static CirclePage<T> fromConnection<T>(
    dynamic connection,
    T Function(Map<String, dynamic> node) parse,
  ) {
    final map = asMap(connection);
    if (map == null) return CirclePage<T>.empty();
    final items = <T>[];
    for (final edge in asMapList(map['edges'])) {
      final node = asMap(edge['node']);
      if (node != null) items.add(parse(node));
    }
    final pageInfo = asMap(map['pageInfo']);
    return CirclePage<T>(
      items: items,
      hasNextPage: asBool(pageInfo?['hasNextPage']),
      endCursor: asStringOrNull(pageInfo?['endCursor']),
      totalCount: map['totalCount'] != null ? asInt(map['totalCount']) : items.length,
    );
  }

  /// Returns a new page appending [next]'s items and adopting its cursor.
  CirclePage<T> merge(CirclePage<T> next) {
    return CirclePage<T>(
      items: [...items, ...next.items],
      hasNextPage: next.hasNextPage,
      endCursor: next.endCursor,
      totalCount: next.totalCount,
    );
  }
}
