import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/graphql/client.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/storage/secure_storage.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final bool isSubmitting;
  final bool biometricRequired;
  final Map<String, dynamic>? user;
  final String? error;

  const AuthState({
    required this.isAuthenticated,
    required this.isLoading,
    this.isSubmitting = false,
    this.biometricRequired = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? isSubmitting,
    bool? biometricRequired,
    Map<String, dynamic>? user,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      biometricRequired: biometricRequired ?? this.biometricRequired,
      user: user ?? this.user,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final graphqlClientProvider = Provider<GraphQLClient>((ref) {
  return buildGraphQLClient();
});

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  Timer? _refreshTimer;

  @override
  AuthState build() {
    ref.onDispose(() => _refreshTimer?.cancel());
    _bootstrap();
    return const AuthState(isAuthenticated: false, isLoading: true);
  }

  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(minutes: 50), _doRefresh);
  }

  Future<void> _doRefresh() async {
    final refreshToken = await SecureStorage.getRefreshToken();
    if (refreshToken == null) return;
    try {
      final client = ref.read(graphqlClientProvider);
      final result = await client.mutate(MutationOptions(
        document: gql(kRefreshToken),
        variables: {'refreshToken': refreshToken},
      ));
      final data = result.data?['refreshToken'];
      if (data != null &&
          data['token'] != null &&
          data['refreshToken'] != null) {
        await SecureStorage.saveTokens(data['token'], data['refreshToken']);
      }
    } catch (_) {
      debugPrint('Token refresh failed — will retry in 2 minutes');
      _refreshTimer = Timer(const Duration(minutes: 2), _doRefresh);
      return;
    }
    _scheduleRefresh();
  }

  Future<void> _bootstrap() async {
    try {
      final token = await SecureStorage.getToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
      if (token == null) {
        state = const AuthState(isAuthenticated: false, isLoading: false);
        return;
      }

      final client = ref.read(graphqlClientProvider);
      final result = await client
          .query(
            QueryOptions(
              document: gql(kMe),
              fetchPolicy: FetchPolicy.networkOnly,
            ),
          )
          .timeout(const Duration(seconds: 25));

      if (result.hasException || result.data?['me'] == null) {
        await SecureStorage.clearTokens();
        state = const AuthState(isAuthenticated: false, isLoading: false);
        return;
      }

      final biometricService = BiometricService();
      if (await biometricService.isEnabled() &&
          await biometricService.isAvailable()) {
        state = AuthState(
          isAuthenticated: false,
          isLoading: false,
          biometricRequired: true,
          user: result.data!['me'],
        );
        return;
      }

      state = AuthState(
          isAuthenticated: true, isLoading: false, user: result.data!['me']);
      _scheduleRefresh();
    } catch (e) {
      debugPrint('Auth bootstrap failed: $e');
      state = const AuthState(
          isAuthenticated: false,
          isLoading: false,
          error: 'Connection error. Check your network.');
    }
  }

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
        state = const AuthState(
          isAuthenticated: false,
          isLoading: false,
          error: 'That username or password is incorrect.',
        );
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

  /// Bootstrap without toggling isLoading (used after login/register so the
  /// router doesn't flash back to /splash mid-submit).
  Future<void> _bootstrapSilent() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        state = const AuthState(isAuthenticated: false, isLoading: false);
        return;
      }
      final client = ref.read(graphqlClientProvider);
      final result = await client
          .query(QueryOptions(
              document: gql(kMe), fetchPolicy: FetchPolicy.networkOnly))
          .timeout(const Duration(seconds: 25));
      if (result.hasException || result.data?['me'] == null) {
        await SecureStorage.clearTokens();
        state = const AuthState(isAuthenticated: false, isLoading: false);
        return;
      }
      state = AuthState(
          isAuthenticated: true,
          isLoading: false,
          isSubmitting: false,
          user: result.data!['me']);
      // Claim daily credits silently — fire and forget
      unawaited(_claimDailyCredits());
    } catch (e) {
      debugPrint('Silent bootstrap failed: $e');
      state = const AuthState(
          isAuthenticated: false,
          isLoading: false,
          error: 'Connection error. Check your network.');
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

  Future<void> completeBiometric() async {
    state = AuthState(
      isAuthenticated: true,
      isLoading: false,
      biometricRequired: false,
      user: state.user,
    );
    _scheduleRefresh();
  }

  Future<void> failBiometric() async {
    await SecureStorage.clearTokens();
    state = const AuthState(
      isAuthenticated: false,
      isLoading: false,
      biometricRequired: false,
    );
  }

  Future<void> _claimDailyCredits() async {
    try {
      final client = ref.read(graphqlClientProvider);
      await client.mutate(MutationOptions(
        document: gql(kClaimDailyCredits),
      ));
    } catch (e) {
      debugPrint('Daily credits claim failed (non-critical): $e');
    }
  }

  Future<void> logout() async {
    _refreshTimer?.cancel();
    await SecureStorage.clearTokens();
    state = const AuthState(isAuthenticated: false, isLoading: false);
  }

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

  /// Reload `me` after profile / education updates (e.g. Edit profile).
  Future<void> refreshUser() async {
    final token = await SecureStorage.getToken();
    if (token == null) return;
    try {
      final client = ref.read(graphqlClientProvider);
      final result = await client.query(
        QueryOptions(document: gql(kMe), fetchPolicy: FetchPolicy.networkOnly),
      );
      if (result.data?['me'] != null) {
        state = AuthState(
            isAuthenticated: true, isLoading: false, user: result.data!['me']);
      }
    } catch (e) {
      debugPrint('refreshUser failed: $e');
    }
  }
}
