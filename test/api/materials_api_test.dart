import 'package:flutter_test/flutter_test.dart';
import 'helpers/gql_helper.dart';

void main() {
  late String token;

  setUpAll(() async {
    final user = await createTestUser();
    token = user.token;
  });

  group('Materials & Quizzes API', () {
    test('Subjects list returns data', () async {
      final result = await gqlPost('''
        query Subjects {
          subjects { id name educationLevel }
        }
      ''', token: token);

      expect(result['data']?['subjects'], isA<List>());
      expect((result['data']!['subjects'] as List).isNotEmpty, isTrue);
    });

    test('Materials list returns data', () async {
      final result = await gqlPost('''
        query Materials(\$limit: Int) {
          materials(limit: \$limit) { id title slug contentType subject { name } }
        }
      ''', variables: {'limit': 5}, token: token);

      expect(result['data']?['materials'], isA<List>());
    });

    test('Quizzes list returns data', () async {
      final result = await gqlPost('''
        query Quizzes(\$limit: Int) {
          quizzes(limit: \$limit) { id title slug difficulty questionCount subject { name } }
        }
      ''', variables: {'limit': 5}, token: token);

      expect(result['data']?['quizzes'], isA<List>());
    });
  });
}
