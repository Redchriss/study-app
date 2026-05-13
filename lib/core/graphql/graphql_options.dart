import 'package:graphql_flutter/graphql_flutter.dart';

class GraphQLOptions {
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration longTimeout = Duration(seconds: 60);

  static QueryOptions query(
    String document, {
    Map<String, dynamic>? variables,
    FetchPolicy? fetchPolicy,
    Duration timeout = defaultTimeout,
  }) {
    return QueryOptions(
      document: gql(document),
      variables: variables ?? const <String, dynamic>{},
      fetchPolicy: fetchPolicy ?? FetchPolicy.networkOnly,
    );
  }

  static MutationOptions mutation(
    String document, {
    Map<String, dynamic>? variables,
    FetchPolicy? fetchPolicy,
    Duration timeout = defaultTimeout,
  }) {
    return MutationOptions(
      document: gql(document),
      variables: variables ?? const <String, dynamic>{},
      fetchPolicy: fetchPolicy ?? FetchPolicy.noCache,
    );
  }

  static WatchQueryOptions watchQuery(
    String document, {
    Map<String, dynamic>? variables,
    FetchPolicy? fetchPolicy,
    Duration timeout = defaultTimeout,
  }) {
    return WatchQueryOptions(
      document: gql(document),
      variables: variables ?? const <String, dynamic>{},
      fetchPolicy: fetchPolicy ?? FetchPolicy.cacheAndNetwork,
    );
  }
}
