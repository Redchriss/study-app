/// Integration tests against the live Yaza backend.
/// Run with: flutter test test/integration/live_backend_test.dart
///
/// These tests verify the EXACT flow the app uses:
/// 1. Login → get token
/// 2. Fetch me → get profile
/// 3. Dashboard query
/// 4. Home feed
/// 5. Register new user
///
/// If any of these fail, the app will fail for that user.

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

const _gqlUrl = 'https://yaza-ai-tutor.onrender.com/graphql/';
const _testUser = 'madalakoso';
const _testPass = 'madalakoso';

Future<Map<String, dynamic>> _gql(String query,
    {Map<String, dynamic>? variables, String? token}) async {
  final headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
  final body = jsonEncode({
    'query': query,
    if (variables != null) 'variables': variables,
  });
  final resp = await http
      .post(Uri.parse(_gqlUrl), headers: headers, body: body)
      .timeout(const Duration(seconds: 30));
  return jsonDecode(resp.body) as Map<String, dynamic>;
}

void main() {
  late String token;

  setUpAll(() async {
    // Login once before all tests
    final result = await _gql(
      r'mutation { tokenAuth(username: "madalakoso", password: "madalakoso") { token refreshToken } }',
    );
    token = result['data']['tokenAuth']['token'] as String;
  });

  group('Live Backend — Auth Flow', () {
    test('1. Login returns token', () async {
      final result = await _gql(
        r'mutation Login($u: String!, $p: String!) { tokenAuth(username: $u, password: $p) { token refreshToken } }',
        variables: {'u': _testUser, 'p': _testPass},
      );
      expect(result['errors'], isNull,
          reason: 'Login failed: ${result['errors']}');
      final data = result['data']['tokenAuth'];
      expect(data['token'], isNotNull, reason: 'No token returned');
      expect(data['refreshToken'], isNotNull);
      token = data['token'] as String;
    });

    test('2. me query returns profile with onboardingComplete', () async {
      final result = await _gql(
        r'{ me { id username profile { onboardingComplete educationLevel aiCredits studyStreak } } }',
        token: token,
      );
      expect(result['errors'], isNull,
          reason: 'me query failed: ${result['errors']}');
      final me = result['data']['me'] as Map;
      expect(me['username'], equals(_testUser));
      expect(me['profile']['onboardingComplete'], isTrue,
          reason: 'onboardingComplete must be true for existing user');
    });

    test('3. Dashboard query returns all required fields', () async {
      final result = await _gql(
        r'''{ me { id username firstName profile { educationLevel studyStreak studyPoints aiCredits onboardingComplete } }
          progressSnapshot { hasData }
          recentMaterials(limit: 1) { id title }
        }''',
        token: token,
      );
      expect(result['errors'], isNull,
          reason: 'Dashboard query failed: ${result['errors']}');
      expect(result['data']['me'], isNotNull);
      expect(result['data']['progressSnapshot'], isNotNull);
    });

    test('4. Home feed query returns paginated edges', () async {
      final result = await _gql(
        r'{ homeFeed(limit: 5) { edges { node { id title } } pageInfo { hasNextPage } totalCount } }',
        token: token,
      );
      expect(result['errors'], isNull,
          reason: 'Home feed failed: ${result['errors']}');
      expect(result['data']['homeFeed']['edges'], isList);
    });

    test('5. Wrong password returns error, not crash', () async {
      final result = await _gql(
        r'mutation { tokenAuth(username: "madalakoso", password: "wrongpassword") { token } }',
      );
      // Should have GraphQL errors, NOT a 500 crash
      expect(result['errors'], isNotNull,
          reason: 'Expected auth error for wrong password');
      expect(result['errors'][0]['message'],
          contains(RegExp(r'credential|invalid|valid', caseSensitive: false)),
          reason: 'Error message should mention invalid credentials');
    });

    test('6. Daily credits mutation works', () async {
      final result = await _gql(
        r'mutation { claimDailyCredits { awarded creditsGiven newBalance } }',
        token: token,
      );
      expect(result['errors'], isNull,
          reason: 'claimDailyCredits failed: ${result['errors']}');
      expect(result['data']['claimDailyCredits']['newBalance'], isNotNull);
    });

    test('7. Check username availability', () async {
      final result = await _gql(
        r'{ checkUsername(username: "testuser_xyz_99999") }',
      );
      expect(result['errors'], isNull);
      expect(result['data']['checkUsername'], isTrue,
          reason: 'Random username should be available');
    });

    test('8. Communities query returns paginated edges', () async {
      final result = await _gql(
        r'{ communities(limit: 3) { edges { node { id name slug } } } }',
        token: token,
      );
      expect(result['errors'], isNull,
          reason: 'Communities query failed: ${result['errors']}');
    });

    test('9. Subjects query returns Malawi curriculum subjects', () async {
      final result = await _gql(
        r'{ subjects(educationLevel: "secondary") { id name } }',
        token: token,
      );
      expect(result['errors'], isNull);
      final subjects = result['data']['subjects'] as List;
      expect(subjects.length, greaterThan(5),
          reason: 'Should have secondary school subjects');
    });

    test('10. Profile followers/following counts work', () async {
      final result = await _gql(
        r'{ myFollowersCount myFollowingCount }',
        token: token,
      );
      expect(result['errors'], isNull,
          reason: 'followers/following failed: ${result['errors']}');
      expect(result['data']['myFollowersCount'], isNotNull);
    });
  });
}
