part of 'auth_provider.dart';

mixin AuthDeleteAccountMixin on Notifier<AuthState> {
  Future<void> logout();

  Future<String?> deleteAccount(String password) async {
    try {
      final client = ref.read(graphqlClientProvider);
      final result = await client.mutate(MutationOptions(
        document: gql(kDeleteAccount),
        variables: {'password': password},
      ));

      if (result.hasException) {
        return graphQLErrorMessage(
            result.exception, 'Could not delete account.');
      }

      final data = result.data?['deleteAccount'];
      if (data == null || data['success'] != true) {
        final errors = (data?['errors'] as List?)?.join(', ') ??
            'Could not delete account.';
        return errors;
      }

      await logout();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
