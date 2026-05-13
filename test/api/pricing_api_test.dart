import 'package:flutter_test/flutter_test.dart';
import 'helpers/gql_helper.dart';

void main() {
  late String token;

  setUpAll(() async {
    final user = await createTestUser();
    token = user.token;
  });

  group('Pricing & Leaderboard API', () {
    test('Credit packages listed with pricing', () async {
      final result = await gqlPost('''
        query Pricing {
          creditPackages { code name amount credits label purchaseType badge }
          aiActionCatalog { code label cost description }
        }
      ''', token: token);

      expect((result['data']?['creditPackages'] as List?)?.isNotEmpty, isTrue,
          reason: 'No credit packages returned');
      expect(result['data']?['aiActionCatalog'], isA<List>());
    });

    test('Leaderboard returns rankings', () async {
      final result = await gqlPost('''
        query Leaderboard(\$category: String) {
          leaderboard(category: \$category, limit: 10) {
            username score quizCount questionsCorrect
          }
        }
      ''', variables: {'category': 'learners'}, token: token);

      expect(result['data']?['leaderboard'], isA<List>());
    });
  });
}
