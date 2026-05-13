import 'package:flutter_test/flutter_test.dart';
import 'helpers/gql_helper.dart';

void main() {
  group('Auth API', () {
    test('Register creates new user and returns token', () async {
      final result = await gqlPost('''
        mutation Register(\$username: String!, \$email: String!, \$password: String!) {
          register(username: \$username, email: \$email, password: \$password) {
            success token refreshToken errors
          }
        }
      ''', variables: {
        'username': 'auth_test_${DateTime.now().millisecondsSinceEpoch}',
        'email': 'auth_test@test.com',
        'password': 'TestPass123!',
      });

      expect(result['data']?['register']?['success'], isTrue);
      expect(result['data']?['register']?['token'], isA<String>());
      expect(result['data']?['register']?['refreshToken'], isA<String>());
    });

    test('Login with valid credentials returns token', () async {
      final user = await createTestUser();
      expect(user.token, isA<String>());
      expect(user.username, startsWith('api_test_'));
    });

    test('Login with invalid credentials returns error', () async {
      final result = await gqlPost('''
        mutation Login(\$username: String!, \$password: String!) {
          tokenAuth(username: \$username, password: \$password) { token }
        }
      ''', variables: {
        'username': 'nonexistent_user',
        'password': 'wrong',
      });

      expect(result['errors'], isNotNull);
    });

    test('Duplicate registration fails', () async {
      final user = await createTestUser();
      final result = await gqlPost('''
        mutation Register(\$username: String!, \$email: String!, \$password: String!) {
          register(username: \$username, email: \$email, password: \$password) {
            success errors
          }
        }
      ''', variables: {
        'username': user.username,
        'email': 'dup_${user.username}@test.com',
        'password': 'TestPass123!',
      });

      expect(result['data']?['register']?['success'], isFalse);
      expect(result['data']?['register']?['errors'], isNotEmpty);
    });

    test('Token refresh works end-to-end', () async {
      final user = await createTestUser();
      final loginResult = await gqlPost('''
        mutation Login(\$username: String!, \$password: String!) {
          tokenAuth(username: \$username, password: \$password) { refreshToken }
        }
      ''', variables: {'username': user.username, 'password': 'TestPass123!'});

      final refreshToken = loginResult['data']?['tokenAuth']?['refreshToken'];
      expect(refreshToken, isNotNull);

      final result = await gqlPost('''
        mutation Refresh(\$refreshToken: String!) {
          refreshToken(refreshToken: \$refreshToken) { token refreshToken }
        }
      ''', variables: {'refreshToken': refreshToken});

      expect(result['data']?['refreshToken']?['token'], isNotNull);
    });

    test('Unauthenticated me query returns null', () async {
      final result = await gqlPost('query Me { me { id } }');
      expect(result['data']?['me'], isNull);
    });
  });
}
