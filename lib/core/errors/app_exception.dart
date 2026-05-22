import 'package:graphql_flutter/graphql_flutter.dart';

String graphQLErrorMessage(OperationException? exception, [String fallback = 'Something went wrong']) {
  return exception?.graphqlErrors.firstOrNull?.message ??
      exception?.linkException?.toString() ??
      fallback;
}

extension GraphQLErrorX on OperationException? {
  String get userMessage => graphQLErrorMessage(this);

  String orFallback(String fallback) => graphQLErrorMessage(this, fallback);
}
