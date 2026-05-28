import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Live GraphQL endpoint for API tests. Override with `GRAPHQL_TEST_URL` (e.g. local Django).
String get graphqlTestUrl {
  final fromEnv = Platform.environment['GRAPHQL_TEST_URL'];
  if (fromEnv != null && fromEnv.isNotEmpty) {
    return fromEnv;
  }
  return 'https://yaza-ai-tutor.onrender.com/graphql/';
}

Map<String, dynamic> gqlBody(String query, {Map<String, dynamic>? variables}) {
  return {
    'query': query,
    if (variables != null) 'variables': variables,
  };
}

Future<Map<String, dynamic>> gqlPost(String query,
    {Map<String, dynamic>? variables, String? token}) async {
  final headers = <String, String>{'Content-Type': 'application/json'};
  if (token != null) headers['Authorization'] = 'Bearer $token';

  final response = await http
      .post(
        Uri.parse(graphqlTestUrl),
        headers: headers,
        body: jsonEncode(gqlBody(query, variables: variables)),
      )
      .timeout(const Duration(seconds: 30));

  final raw = response.body;
  final trimmed = raw.trimLeft();
  if (trimmed.startsWith('<')) {
    final preview =
        trimmed.length > 200 ? '${trimmed.substring(0, 200)}…' : trimmed;
    throw StateError(
      'GraphQL at $graphqlTestUrl returned HTML (HTTP ${response.statusCode}), not JSON. '
      'Usually a Django 500 / schema import error. Preview: $preview',
    );
  }
  try {
    return jsonDecode(raw) as Map<String, dynamic>;
  } on FormatException catch (e) {
    throw StateError(
        'GraphQL response is not JSON ($e). First chars: ${trimmed.substring(0, trimmed.length > 80 ? 80 : trimmed.length)}');
  }
}

/// Creates a unique test user and returns their token. Used by multiple test files.
Future<({String username, String token, String refreshToken})>
    createTestUser() async {
  final ts = DateTime.now().millisecondsSinceEpoch;
  final username = 'api_test_${ts}_${ts % 10000}';
  const password = 'TestPass123!';

  final result = await gqlPost('''
    mutation Register(\$username: String!, \$email: String!, \$password: String!) {
      register(username: \$username, email: \$email, password: \$password) {
        success token refreshToken
      }
    }
  ''', variables: {
    'username': username,
    'email': '$username@test.com',
    'password': password,
  });

  final data = result['data']!['register']!;
  return (
    username: username,
    token: data['token'] as String,
    refreshToken: data['refreshToken'] as String,
  );
}
