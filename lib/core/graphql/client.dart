import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/io_client.dart';
import '../config/app_config.dart';
import '../storage/secure_storage.dart';

GraphQLCache _buildGraphQLCache() {
  try {
    return GraphQLCache(store: HiveStore());
  } catch (_) {
    return GraphQLCache();
  }
}

/// Retry link with exponential backoff (up to 3 retries).
class _RetryLink extends Link {
  const _RetryLink();

  @override
  Stream<Response> request(Request req, [NextLink? forward]) {
    return _retry(req, forward!, 0);
  }

  Stream<Response> _retry(Request req, NextLink forward, int attempt) {
    StreamController<Response>? controller;
    StreamSubscription<Response>? sub;

    controller = StreamController<Response>(onCancel: () => sub?.cancel());

    sub = forward(req).listen(
      (response) {
        controller!.add(response);
      },
      onError: (Object error) async {
        if (attempt < 3 && error is LinkException) {
          final delay = const Duration(seconds: 1) * (1 << attempt);
          await Future.delayed(delay);
          await sub?.cancel();
          _retry(req, forward, attempt + 1).pipe(controller!);
        } else {
          controller!.addError(error);
          await controller.close();
        }
      },
      onDone: () => controller!.close(),
      cancelOnError: false,
    );

    return controller.stream;
  }
}

/// Handles 401 / auth errors by refreshing the token and retrying.
class _AuthErrorLink extends Link {
  /// Guards against concurrent refresh calls (race condition fix).
  Completer<void>? _refreshCompleter;

  @override
  Stream<Response> request(Request req, [NextLink? forward]) async* {
    try {
      await for (final response in forward!(req)) {
        final hasAuthError = response.errors?.any((e) {
              final msg = e.message.toLowerCase();
              return msg.contains('not authenticated') ||
                  msg.contains('token expired') ||
                  msg.contains('unauthorized');
            }) ==
            true;

        if (hasAuthError) {
          await _tryRefreshToken();
          yield* forward(req);
          return;
        }
        yield response;
      }
    } on ServerException catch (e) {
      if (e.statusCode == 401) {
        await _tryRefreshToken();
        yield* forward!(req);
        return;
      }
      rethrow;
    }
  }

  Future<void> _tryRefreshToken() async {
    // Deduplicate concurrent refresh calls — only one refresh runs at a time
    if (_refreshCompleter != null) {
      await _refreshCompleter!.future;
      return;
    }
    _refreshCompleter = Completer<void>();
    final refreshToken = await SecureStorage.getRefreshToken();
    if (refreshToken == null) {
      await SecureStorage.clearTokens();
      return;
    }
    final inner = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    final client = IOClient(inner);
    try {
      final request = await client.post(
        Uri.parse(AppConfig.graphqlUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': '''
            mutation RefreshToken(\$refreshToken: String!) {
              refreshToken(refreshToken: \$refreshToken) {
                token
                refreshToken
              }
            }
          ''',
          'variables': {'refreshToken': refreshToken},
        }),
      );
      if (request.statusCode == 200) {
        final data = jsonDecode(request.body)['data']?['refreshToken'];
        if (data != null && data['token'] != null) {
          await SecureStorage.saveTokens(data['token'], data['refreshToken']);
          return;
        }
        // Server rejected the refresh token — now it's safe to clear
        await SecureStorage.clearTokens();
      }
      // Non-200 = network/server error, don't clear tokens
    } catch (_) {
      // Don't clear tokens on refresh network failure — just let the next request retry
      return;
    } finally {
      client.close();
      _refreshCompleter?.complete();
      _refreshCompleter = null;
    }
  }
}

GraphQLClient buildGraphQLClient() {
  final inner = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15)
    ..idleTimeout = const Duration(seconds: 10);

  final authLink = AuthLink(
    getToken: () async {
      final token = await SecureStorage.getToken();
      return token != null ? 'Bearer $token' : null;
    },
  );

  final httpLink = HttpLink(
    AppConfig.graphqlUrl,
    httpClient: IOClient(inner),
  );

  // Order: retry → authError → auth → http
  final link = const _RetryLink()
      .concat(_AuthErrorLink())
      .concat(authLink)
      .concat(httpLink);

  return GraphQLClient(
    link: link,
    cache: _buildGraphQLCache(),
    defaultPolicies: DefaultPolicies(
      query: Policies(
        fetch: FetchPolicy.cacheAndNetwork,
      ),
      mutate: Policies(
        fetch: FetchPolicy.networkOnly,
      ),
    ),
  );
}
