part of 'auth_provider.dart';

mixin AuthRegisterMixin on Notifier<AuthState> {
  Future<void> _bootstrapSilent();
  void _scheduleRefresh();

  Future<bool> register(String username, String email, String password,
      {String? phone, String? fullName}) async {
    try {
      state = const AuthState(
        isAuthenticated: false,
        isLoading: false,
        isSubmitting: true,
      );
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
      final result = await client
          .mutate(MutationOptions(
            document: gql(kRegister),
            variables: variables,
          ))
          .timeout(const Duration(seconds: 25));

      if (result.hasException) {
        final msg = _registerErrorMessage(result.exception);
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
    } on TimeoutException {
      state = const AuthState(
        isAuthenticated: false,
        isLoading: false,
        error:
            'Creating your account is taking too long. Check your connection and try again.',
      );
      return false;
    } catch (e) {
      debugPrint('Registration failed: $e');
      state = const AuthState(
        isAuthenticated: false,
        isLoading: false,
        error: 'Could not create your account right now. Please try again.',
      );
      return false;
    }
  }

  String _registerErrorMessage(OperationException? exception) {
    final raw = graphQLErrorMessage(exception, '').toLowerCase();
    if (raw.contains('username') && raw.contains('taken')) {
      return 'That username is already taken.';
    }
    if (raw.contains('email') && raw.contains('exist')) {
      return 'An account already exists with that email.';
    }
    if (raw.contains('password')) {
      return 'Choose a stronger password and try again.';
    }
    if (raw.contains('socket') ||
        raw.contains('connection') ||
        raw.contains('network') ||
        raw.contains('timeout')) {
      return 'Connection problem. Check your internet and try again.';
    }
    if (raw.contains('500') || raw.contains('server') || raw.contains('html')) {
      return 'The server is having trouble creating accounts. Try again shortly.';
    }
    return 'Could not create your account. Check your details and try again.';
  }
}
