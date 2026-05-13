import 'package:flutter_test/flutter_test.dart';
import 'helpers/gql_helper.dart';

void main() {
  late String token;

  setUpAll(() async {
    final user = await createTestUser();
    token = user.token;
  });

  group('Dashboard API', () {
    test('Me returns full user profile', () async {
      final result = await gqlPost('''
        query Me {
          me { id username email profile { educationLevel onboardingComplete aiCredits studyPoints studyStreak } }
        }
      ''', token: token);

      expect(result['data']?['me']?['username'], isA<String>());
      expect(result['data']?['me']?['profile']?['aiCredits'], isA<int>());
    });

    test('Profile update succeeds', () async {
      final result = await gqlPost('''
        mutation UpdateProfile(\$input: ProfileInput!) {
          updateProfile(input: \$input) { success errors }
        }
      ''', variables: {
        'input': {'educationLevel': 'secondary', 'form': 3, 'term': '1'}
      }, token: token);

      expect(result['data']?['updateProfile']?['success'], isTrue);
    });

    test('Dashboard returns all sections', () async {
      final result = await gqlPost('''
        query Dashboard {
          me { username }
          recentMaterials(limit: 3) { id title }
          recentQuizAttempts(limit: 3) { id score }
          progressSnapshot { hasData masteryPercent avgQuizScore questionsPracticed questionsCorrect attemptCount }
          activityFeed(limit: 3) { kind message createdAt }
          learningProfile { learningStyle }
          myCircles { id name }
        }
      ''', token: token);

      expect(result['data']?['progressSnapshot'], isNotNull);
      expect(result['data']?['myCircles'], isA<List>());
    });
  });
}
