import 'package:graphql_flutter/graphql_flutter.dart';
import '../config/app_config.dart';
import '../storage/secure_storage.dart';

GraphQLClient buildGraphQLClient() {
  final authLink = AuthLink(
    getToken: () async {
      final token = await SecureStorage.getToken();
      return token != null ? 'Bearer $token' : null;
    },
  );

  final httpLink = HttpLink(AppConfig.graphqlUrl);
  final link = authLink.concat(httpLink);

  return GraphQLClient(
    link: link,
    cache: GraphQLCache(store: HiveStore()),
    defaultPolicies: DefaultPolicies(
      query: Policies(fetch: FetchPolicy.networkOnly),
      mutate: Policies(fetch: FetchPolicy.networkOnly),
    ),
  );
}
