part of 'auth_provider.dart';

mixin AuthRegisterMixin on Notifier<AuthState> {
  Future<void> _bootstrapSilent();
  void _scheduleRefresh();

  Future<bool> register(String username, String email, String password,
      {String? phone, String? fullName}) async {
    try {
      state = const AuthState(isAuthenticated: false, isLoading: true);
      final client = ref.read(graphqlClientProvider);
      final variables = {
        'username': username,
        'email': email,
        'password': password,
        'phone': phone,
      };
      if (fullName != null && fullName.isNotEmpty) {
        final parts = fullName.trim().split(' ');
        variables['firstName'] = parts.first;
        if (parts.length > 1) variables['lastName'] = parts.skip(1).join(' ');
      }
      final result = await client.mutate(MutationOptions(
        document: gql(kRegister),
        variables: variables,
      ));

      if (result.hasException) {
        final msg = graphQLErrorMessage(
            result.exception, 'Network error. Check your connection.');
        state = AuthState(isAuthenticated: false, isLoading: false, error: msg);
        return false;
      }

      final data = result.data?['register'];
      if (data == null) {
        state = const AuthState(
            isAuthenticated: false,
            isLoading: false,
            error: 'Registration failed.');
        return false;
      }
      if (data['success'] != true) {
        final errors =
            (data['errors'] as List?)?.join(', ') ?? 'Registration failed.';
        state =
            AuthState(isAuthenticated: false, isLoading: false, error: errors);
        return false;
      }

      if (data['token'] == null || data['refreshToken'] == null) {
        state = const AuthState(
            isAuthenticated: false,
            isLoading: false,
            error: 'Registration failed.');
        return false;
      }
      await SecureStorage.saveTokens(data['token'], data['refreshToken']);
      await _bootstrapSilent();
      _scheduleRefresh();
      return state.isAuthenticated;
    } catch (e) {
      debugPrint('Registration failed: $e');
      state = AuthState(
          isAuthenticated: false, isLoading: false, error: e.toString());
      return false;
    }
  }
}
