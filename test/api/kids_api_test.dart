import 'package:flutter_test/flutter_test.dart';
import 'helpers/gql_helper.dart';

void main() {
  late String token;

  group('Kids Mode API', () {
    setUpAll(() async {
      final user = await createTestUser();
      token = user.token;
    });

    test('Create child profile succeeds', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final result = await gqlPost('''
        mutation CreateChild(\$name: String!, \$standard: Int!, \$pin: String!) {
          createChildProfile(childName: \$name, standard: \$standard, pinCode: \$pin) {
            success errors child { id childName standard username }
          }
        }
      ''', variables: {
        'name': 'Kid_$ts',
        'standard': 5,
        'pin': '1234',
      }, token: token);

      expect(result['data']?['createChildProfile']?['success'], isTrue);
      expect(result['data']?['createChildProfile']?['child']?['username'], isNotNull);
    });

    test('Kid login with correct PIN succeeds', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final createResult = await gqlPost('''
        mutation CreateChild(\$name: String!, \$standard: Int!, \$pin: String!) {
          createChildProfile(childName: \$name, standard: \$standard, pinCode: \$pin) {
            child { username }
          }
        }
      ''', variables: {'name': 'LoginKid_$ts', 'standard': 5, 'pin': '1234'}, token: token);

      final username = createResult['data']?['createChildProfile']?['child']?['username'];
      expect(username, isNotNull);

      final result = await gqlPost('''
        mutation KidLogin(\$username: String!, \$pin: String!) {
          kidLogin(username: \$username, pinCode: \$pin) { success token }
        }
      ''', variables: {'username': username, 'pin': '1234'});

      expect(result['data']?['kidLogin']?['success'], isTrue);
      expect(result['data']?['kidLogin']?['token'], isNotNull);
    });

    test('Kid login with wrong PIN fails', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final createResult = await gqlPost('''
        mutation CreateChild(\$name: String!, \$standard: Int!, \$pin: String!) {
          createChildProfile(childName: \$name, standard: \$standard, pinCode: \$pin) {
            child { username }
          }
        }
      ''', variables: {'name': 'FailKid_$ts', 'standard': 5, 'pin': '1234'}, token: token);

      final username = createResult['data']?['createChildProfile']?['child']?['username'];
      expect(username, isNotNull);

      final result = await gqlPost('''
        mutation KidLogin(\$username: String!, \$pin: String!) {
          kidLogin(username: \$username, pinCode: \$pin) { success errors }
        }
      ''', variables: {'username': username, 'pin': '0000'});

      expect(result['data']?['kidLogin']?['success'], isFalse);
    });
  });
}
