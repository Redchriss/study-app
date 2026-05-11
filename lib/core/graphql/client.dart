import 'package:graphql_flutter/graphql_flutter.dart';
import '../storage/secure_storage.dart';
import '../config/app_config.dart';

Future<GraphQLClient> buildGraphQLClient() async {
  await initHiveForFlutter();

  final authLink = AuthLink(
    getToken: () async {
      final token = await SecureStorage.getToken();
      return token != null ? 'Bearer $token' : null;
    },
  );

  final httpLink = HttpLink(AppConfig.graphqlUrl);

  final link = authLink.concat(httpLink);

  return GraphQLClient(
    cache: GraphQLCache(store: HiveStore()),
    link: link,
    defaultPolicies: DefaultPolicies(
      query: Policies(fetch: FetchPolicy.cacheAndNetwork),
      mutate: Policies(fetch: FetchPolicy.networkOnly),
    ),
  );
}
