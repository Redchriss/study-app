import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String kApiUrl = 'https://yaza-ai-tutor.onrender.com/graphql/';

Map<String, dynamic> _gql(String query, {Map<String, dynamic>? variables, String? token}) {
  return {
    'query': query,
    if (variables != null) 'variables': variables,
  };
}

Future<Map<String, dynamic>> _post(String query, {Map<String, dynamic>? variables, String? token}) async {
  final headers = <String, String>{
    'Content-Type': 'application/json',
  };
  if (token != null) headers['Authorization'] = 'Bearer $token';

  final response = await http
      .post(Uri.parse(kApiUrl), headers: headers, body: jsonEncode(_gql(query, variables: variables)))
      .timeout(const Duration(seconds: 30));
  return jsonDecode(response.body) as Map<String, dynamic>;
}

String? _testToken;

void main() {
  late String testUsername;
  late String testPassword;

  setUp(() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    testUsername = 'integration_test_${ts}_${(ts % 10000)}';
    testPassword = 'TestPass123!';
  });

  group('GraphQL API Integration Tests', () {
    test('1. Register new user', () async {
      final result = await _post('''
        mutation Register(\$username: String!, \$email: String!, \$password: String!) {
          register(username: \$username, email: \$email, password: \$password) {
            success token refreshToken errors
          }
        }
      ''', variables: {
        'username': testUsername,
        'email': '$testUsername@test.com',
        'password': testPassword,
      });

      expect(result['data']?['register']?['success'], isTrue,
          reason: 'Registration failed: ${result['errors'] ?? result['data']?['register']?['errors']}');
      _testToken = result['data']?['register']?['token'];
      expect(_testToken, isNotNull);
    });

    test('2. Login with created credentials', () async {
      final result = await _post('''
        mutation Login(\$username: String!, \$password: String!) {
          tokenAuth(username: \$username, password: \$password) {
            token refreshToken
          }
        }
      ''', variables: {
        'username': testUsername,
        'password': testPassword,
      });

      expect(result['data']?['tokenAuth']?['token'], isNotNull,
          reason: 'Login failed: ${result['errors']}');
      _testToken = result['data']!['tokenAuth']!['token'] as String?;
    });

    test('3. Fetch authenticated user (me)', () async {
      expect(_testToken, isNotNull, reason: 'No token from previous test');

      final result = await _post('''
        query Me {
          me { id username email profile { educationLevel onboardingComplete aiCredits } }
        }
      ''', token: _testToken);

      expect(result['data']?['me']?['username'], equals(testUsername));
      expect(result['data']?['me']?['profile']?['aiCredits'], isA<int>());
    });

    test('4. Update profile', () async {
      expect(_testToken, isNotNull);

      final result = await _post('''
        mutation UpdateProfile(\$input: ProfileInput!) {
          updateProfile(input: \$input) {
            success errors
            profile { educationLevel }
          }
        }
      ''', variables: {
        'input': {'educationLevel': 'secondary', 'form': 3, 'term': '1'}
      }, token: _testToken);

      expect(result['data']?['updateProfile']?['success'], isTrue,
          reason: 'Profile update failed: ${result['data']?['updateProfile']?['errors']}');
    });

    test('5. Fetch dashboard data', () async {
      expect(_testToken, isNotNull);

      final result = await _post('''
        query Dashboard {
          me { username profile { studyPoints studyStreak aiCredits } }
          progressSnapshot { hasData masteryPercent avgQuizScore questionsPracticed questionsCorrect attemptCount }
          activityFeed(limit: 3) { kind message createdAt }
          learningProfile { learningStyle }
          popularQuizzes { id title slug }
          myCircles { id name slug }
        }
      ''', token: _testToken);

      expect(result['data']?['me'], isNotNull);
      expect(result['data']?['progressSnapshot'], isNotNull);
    });

    test('6. Browse subjects and materials', () async {
      expect(_testToken, isNotNull);

      final result = await _post('''
        query Browse {
          subjects { id name educationLevel }
          materials(limit: 5) { id title slug contentType subject { name } }
        }
      ''', token: _testToken);

      expect(result['data']?['subjects'], isA<List>());
    });

    test('7. Browse quizzes', () async {
      expect(_testToken, isNotNull);

      final result = await _post('''
        query QuizList {
          quizzes(limit: 5) { id title slug difficulty questionCount subject { name } }
        }
      ''', token: _testToken);

      expect(result['data']?['quizzes'], isA<List>());
    });

    test('8. Browse circles', () async {
      expect(_testToken, isNotNull);

      final result = await _post('''
        query CircleList {
          studyCircles { id name slug description memberCount educationLevel }
        }
      ''', token: _testToken);

      expect(result['data']?['studyCircles'], isA<List>());
    });

    test('9. View notifications', () async {
      expect(_testToken, isNotNull);

      final result = await _post('''
        query NotificationList {
          notifications { id notificationType message isRead createdAt }
          unreadNotificationCount
        }
      ''', token: _testToken);

      expect(result['data']?['notifications'], isA<List>());
      expect(result['data']?['unreadNotificationCount'], isA<int>());
    });

    test('10. Fetch leaderboard', () async {
      expect(_testToken, isNotNull);

      final result = await _post('''
        query LeaderboardRankings(\$category: String) {
          leaderboard(category: \$category, limit: 5) {
            username score quizCount questionsCorrect
          }
        }
      ''', variables: {'category': 'learners'}, token: _testToken);

      expect(result['data']?['leaderboard'], isA<List>());
    });

    test('11. Refresh token', () async {
      expect(_testToken, isNotNull);

      final refreshResult = await _post('''
        mutation Login(\$username: String!, \$password: String!) {
          tokenAuth(username: \$username, password: \$password) {
            refreshToken
          }
        }
      ''', variables: {
        'username': testUsername,
        'password': testPassword,
      });

      final refreshToken = refreshResult['data']?['tokenAuth']?['refreshToken'];
      expect(refreshToken, isNotNull);

      final result = await _post('''
        mutation Refresh(\$refreshToken: String!) {
          refreshToken(refreshToken: \$refreshToken) { token refreshToken payload }
        }
      ''', variables: {'refreshToken': refreshToken});

      expect(result['data']?['refreshToken']?['token'], isNotNull,
          reason: 'Token refresh failed: ${result['errors']}');
      _testToken = result['data']!['refreshToken']!['token'] as String?;
    });

    test('12. Unauthenticated access returns null', () async {
      final result = await _post('''
        query Me {
          me { id username }
        }
      ''');

      expect(result['data']?['me'], isNull);
    });

    test('13. Invalid login returns error', () async {
      final result = await _post('''
        mutation Login(\$username: String!, \$password: String!) {
          tokenAuth(username: \$username, password: \$password) { token }
        }
      ''', variables: {
        'username': 'nonexistent_user_xyz',
        'password': 'wrong_password',
      });

      expect(result['errors'], isNotNull,
          reason: 'Expected error for invalid login but got: ${result['data']}');
    });

    test('14. Register duplicate username fails', () async {
      final result = await _post('''
        mutation Register(\$username: String!, \$email: String!, \$password: String!) {
          register(username: \$username, email: \$email, password: \$password) {
            success errors
          }
        }
      ''', variables: {
        'username': testUsername,
        'email': 'another_$testUsername@test.com',
        'password': testPassword,
      });

      expect(result['data']?['register']?['success'], isFalse);
      expect(result['data']?['register']?['errors'], isNotEmpty);
    });

    test('15. Fetch credit packages and pricing', () async {
      expect(_testToken, isNotNull);

      final result = await _post('''
        query Pricing {
          creditPackages { code name amount credits label purchaseType badge }
          aiActionCatalog { code label cost description }
        }
      ''', token: _testToken);

      expect(result['data']?['creditPackages'], isA<List>());
      expect((result['data']?['creditPackages'] as List).isNotEmpty, isTrue,
          reason: 'No credit packages returned');
      expect(result['data']?['aiActionCatalog'], isA<List>());
    });

    test('16. Create and verify child account (kids mode)', () async {
      expect(_testToken, isNotNull);

      final ts = DateTime.now().millisecondsSinceEpoch;
      final childResult = await _post('''
        mutation CreateChild(\$name: String!, \$standard: Int!, \$pin: String!) {
          createChildProfile(childName: \$name, standard: \$standard, pinCode: \$pin) {
            success errors
            child { id childName standard username }
          }
        }
      ''', variables: {
        'name': 'TestKid_$ts',
        'standard': 5,
        'pin': '1234',
      }, token: _testToken);

      expect(childResult['data']?['createChildProfile']?['success'], isTrue,
          reason: 'Child creation failed: ${childResult['data']?['createChildProfile']?['errors']}');

      final childUsername = childResult['data']?['createChildProfile']?['child']?['username'];
      expect(childUsername, isNotNull);

      // Login as kid
      final kidLogin = await _post('''
        mutation KidLogin(\$username: String!, \$pin: String!) {
          kidLogin(username: \$username, pinCode: \$pin) {
            success token errors
            child { childName standard }
          }
        }
      ''', variables: {
        'username': childUsername,
        'pin': '1234',
      });

      expect(kidLogin['data']?['kidLogin']?['success'], isTrue,
          reason: 'Kid login failed: ${kidLogin['errors'] ?? kidLogin['data']?['kidLogin']?['errors']}');
      expect(kidLogin['data']?['kidLogin']?['token'], isNotNull);
    });
  });
}
