import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/graphql/queries/queries.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../domain/circles_domain.dart';

part 'circles_repository_reads.dart';
part 'circles_repository_actions_content.dart';
part 'circles_repository_actions_mod.dart';
part 'circles_repository_actions_flair.dart';

/// Raised when a community GraphQL call fails or returns server-side errors.
class CirclesException implements Exception {
  final String message;
  CirclesException(this.message);

  @override
  String toString() => message;
}

/// Single typed access point for the Circles feature. Every screen/provider
/// should talk to the backend through this repository rather than issuing raw
/// `Query`/`Mutation` widgets, so parsing and error handling stay consistent.
///
/// Read methods live in `circles_repository_reads.dart`; mutating actions live
/// in `circles_repository_actions_content.dart` and
/// `circles_repository_actions_mod.dart` (kept as parts to honour the
/// 250-line-per-file rule).
class CirclesRepository {
  CirclesRepository(this._ref);

  final Ref _ref;

  GraphQLClient get _client => _ref.read(graphqlClientProvider);

  Future<Map<String, dynamic>> _query(
    String document, {
    Map<String, dynamic>? variables,
    FetchPolicy fetchPolicy = FetchPolicy.networkOnly,
  }) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(document),
        variables: variables ?? const {},
        fetchPolicy: fetchPolicy,
      ),
    );
    if (result.hasException) {
      throw CirclesException(
        graphQLErrorMessage(result.exception, 'Could not load community data'),
      );
    }
    return result.data ?? const {};
  }

  Future<Map<String, dynamic>> _mutate(
    String document, {
    Map<String, dynamic>? variables,
  }) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(document),
        variables: variables ?? const {},
      ),
    );
    if (result.hasException) {
      throw CirclesException(
        graphQLErrorMessage(result.exception, 'Action failed'),
      );
    }
    return result.data ?? const {};
  }

  /// Surfaces a payload's `errors: [String]` array as a [CirclesException].
  void _throwIfPayloadErrors(dynamic payload) {
    final errors = asMap(payload)?['errors'];
    if (errors is List && errors.isNotEmpty) {
      throw CirclesException(errors.first.toString());
    }
  }

  /// Returns whether a `{ success }` payload succeeded.
  bool _isSuccess(dynamic payload) => asBool(asMap(payload)?['success']);
}
