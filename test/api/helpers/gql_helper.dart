import 'dart:convert';
import 'package:http/http.dart' as http;

const String kApiUrl = 'https://yaza-ai-tutor.onrender.com/graphql/';

Map<String, dynamic> gqlBody(String query, {Map<String, dynamic>? variables}) {
  return {
    'query': query,
    if (variables != null) 'variables': variables,
  };
}

Future<Map<String, dynamic>> gqlPost(String query, {Map<String, dynamic>? variables, String? token}) async {
  final headers = <String, String>{'Content-Type': 'application/json'};
  if (token != null) headers['Authorization'] = 'Bearer $token';

  final response = await http
      .post(Uri.parse(kApiUrl), headers: headers, body: jsonEncode(gqlBody(query, variables: variables)))
      .timeout(const Duration(seconds: 30));
  return jsonDecode(response.body) as Map<String, dynamic>;
}

/// Creates a unique test user and returns their token. Used by multiple test files.
Future<({String username, String token, String refreshToken})> createTestUser() async {
  final ts = DateTime.now().millisecondsSinceEpoch;
  final username = 'api_test_${ts}_${ts % 10000}';
  final password = 'TestPass123!';

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
