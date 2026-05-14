import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/client.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/storage/secure_storage.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final Map<String, dynamic>? user;
  final String? error;

  const AuthState({
    required this.isAuthenticated,
    required this.isLoading,
    this.user,
    this.error,
  });
}

final graphqlClientProvider = Provider<GraphQLClient>((ref) {
  return buildGraphQLClient();
});

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  Timer? _refreshTimer;

  String _errorMessage(OperationException? exception, [String fallback = 'Network error. Check your connection.']) {
    return exception?.graphqlErrors.firstOrNull?.message ??
        exception?.linkException?.toString() ??
        fallback;
  }

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
      if (data != null && data['token'] != null && data['refreshToken'] != null) {
        await SecureStorage.saveTokens(data['token'], data['refreshToken']);
        _scheduleRefresh();
      }
    } catch (_) {}
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
      final result = await client.query(
        QueryOptions(
          document: gql(kMe),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      ).timeout(const Duration(seconds: 25));

      if (result.hasException || result.data?['me'] == null) {
        await SecureStorage.clearTokens();
        state = const AuthState(isAuthenticated: false, isLoading: false);
        return;
      }

      state = AuthState(isAuthenticated: true, isLoading: false, user: result.data!['me']);
      _scheduleRefresh();
    } catch (e) {
      debugPrint('Auth bootstrap failed: $e');
      state = const AuthState(isAuthenticated: false, isLoading: false, error: 'Connection error. Check your network.');
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      state = AuthState(isAuthenticated: false, isLoading: true);
      final client = ref.read(graphqlClientProvider);
      final result = await client.mutate(MutationOptions(
        document: gql(kTokenAuth),
        variables: {'username': username, 'password': password},
      ));

      if (result.hasException) {
        final msg = _errorMessage(result.exception);
        state = AuthState(isAuthenticated: false, isLoading: false, error: msg);
        return false;
      }

      final data = result.data?['tokenAuth'];
      if (data == null || data['token'] == null || data['refreshToken'] == null) {
        state = const AuthState(isAuthenticated: false, isLoading: false, error: 'Login failed.');
        return false;
      }
      await SecureStorage.saveTokens(data['token'], data['refreshToken']);
      await _bootstrap();
      _scheduleRefresh();
      return state.isAuthenticated;
    } catch (e) {
      debugPrint('Login failed: $e');
      state = AuthState(isAuthenticated: false, isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> register(String username, String email, String password, {String? phone}) async {
    try {
      state = AuthState(isAuthenticated: false, isLoading: true);
      final client = ref.read(graphqlClientProvider);
      final result = await client.mutate(MutationOptions(
        document: gql(kRegister),
        variables: {'username': username, 'email': email, 'password': password, 'phone': phone},
      ));

      if (result.hasException) {
        final msg = _errorMessage(result.exception);
        state = AuthState(isAuthenticated: false, isLoading: false, error: msg);
        return false;
      }

      final data = result.data?['register'];
      if (data == null) {
        state = const AuthState(isAuthenticated: false, isLoading: false, error: 'Registration failed.');
        return false;
      }
      if (data['success'] != true) {
        final errors = (data['errors'] as List?)?.join(', ') ?? 'Registration failed.';
        state = AuthState(isAuthenticated: false, isLoading: false, error: errors);
        return false;
      }

      if (data['token'] == null || data['refreshToken'] == null) {
        state = const AuthState(isAuthenticated: false, isLoading: false, error: 'Registration failed.');
        return false;
      }
      await SecureStorage.saveTokens(data['token'], data['refreshToken']);
      await _bootstrap();
      _scheduleRefresh();
      return state.isAuthenticated;
    } catch (e) {
      debugPrint('Registration failed: $e');
      state = AuthState(isAuthenticated: false, isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    _refreshTimer?.cancel();
    await SecureStorage.clearTokens();
    state = const AuthState(isAuthenticated: false, isLoading: false);
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
        state = AuthState(isAuthenticated: true, isLoading: false, user: result.data!['me']);
      }
    } catch (e) {
      debugPrint('refreshUser failed: $e');
    }
  }
}
