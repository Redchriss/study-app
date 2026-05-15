import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../core/config/app_config.dart';

class KidGraphqlClient {
  KidGraphqlClient._();

  static GraphQLClient? _client;
  static String? _token;

  static GraphQLClient fromToken(String? token) {
    if (_client != null && token == _token) return _client!;
    final link = AuthLink(
      getToken: () async => token == null ? null : 'Bearer $token',
    ).concat(HttpLink(AppConfig.graphqlUrl));
    _token = token;
    _client = GraphQLClient(cache: GraphQLCache(), link: link);
    return _client!;
  }
}
