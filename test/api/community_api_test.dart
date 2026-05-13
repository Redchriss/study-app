import 'package:flutter_test/flutter_test.dart';
import 'helpers/gql_helper.dart';

void main() {
  late String token;

  setUpAll(() async {
    final user = await createTestUser();
    token = user.token;
  });

  group('Circles & Community API', () {
    test('Study circles list returns data', () async {
      final result = await gqlPost('''
        query Circles {
          studyCircles { id name slug description memberCount educationLevel isMember }
        }
      ''', token: token);

      expect(result['data']?['studyCircles'], isA<List>());
    });

    test('Notifications return data', () async {
      final result = await gqlPost('''
        query Notifications {
          notifications { id notificationType message isRead createdAt }
          unreadNotificationCount
        }
      ''', token: token);

      expect(result['data']?['notifications'], isA<List>());
      expect(result['data']?['unreadNotificationCount'], isA<int>());
    });
  });
}
