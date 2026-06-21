part of 'auth_provider.dart';

mixin AuthLoginMixin on Notifier<AuthState> {
  Future<void> _bootstrapSilent();
  void _scheduleRefresh();

  Future<bool> login(String username, String password) async {
    try {
      state = const AuthState(
        isAuthenticated: false,
        isLoading: false,
        isSubmitting: true,
      );
      final client = ref.read(graphqlClientProvider);
      final result = await client
          .mutate(MutationOptions(
            document: gql(kTokenAuth),
            variables: {'username': username, 'password': password},
          ))
          .timeout(const Duration(seconds: 25));

      if (result.hasException) {
        final msg = _loginErrorMessage(result.exception);
        state = AuthState(isAuthenticated: false, isLoading: false, error: msg);
        return false;
      }

      final data = result.data?['tokenAuth'];
      if (data == null ||
          data['token'] == null ||
          data['refreshToken'] == null) {
        // Check for a human-readable error from the new Login mutation
        final errors = (data?['errors'] as List?)?.whereType<String>().toList();
        if (errors != null && errors.isNotEmpty) {
          state = AuthState(
            isAuthenticated: false,
            isLoading: false,
            error: errors.join(' '),
          );
        } else {
          state = const AuthState(
            isAuthenticated: false,
            isLoading: false,
            error: 'That username or password is incorrect.',
          );
        }
        return false;
      }
      await SecureStorage.saveTokens(data['token'], data['refreshToken']);
      // Bootstrap silently — keep isSubmitting true so router doesn't redirect
      await _bootstrapSilent();
      _scheduleRefresh();
      return state.isAuthenticated;
    } on TimeoutException {
      state = const AuthState(
        isAuthenticated: false,
        isLoading: false,
        error: 'Login is taking too long. Check your connection and try again.',
      );
      return false;
    } catch (e) {
      debugPrint('Login failed: $e');
      state = const AuthState(
        isAuthenticated: false,
        isLoading: false,
        error: 'Could not log in right now. Please try again.',
      );
      return false;
    }
  }

  String _loginErrorMessage(OperationException? exception) {
    final raw = graphQLErrorMessage(exception, '').toLowerCase();
    if (raw.contains('invalid') ||
        raw.contains('credential') ||
        raw.contains('password') ||
        raw.contains('username') ||
        raw.contains('unable to log in')) {
      return 'That username or password is incorrect.';
    }
    if (raw.contains('socket') ||
        raw.contains('connection') ||
        raw.contains('network') ||
        raw.contains('timeout')) {
      return 'Connection problem. Check your internet and try again.';
    }
    if (raw.contains('500') ||
        raw.contains('server') ||
        raw.contains('html') ||
        raw.contains('formatException'.toLowerCase())) {
      return 'The server is having trouble logging you in. Try again shortly.';
    }
    return 'Could not log in. Check your details and try again.';
  }
}
