import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/graphql/queries/queries.dart';

// GraphQL client provider
final graphqlClientProvider = FutureProvider<GraphQLClient>((ref) async {
  return buildGraphQLClient();
});

// Auth state
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final Map<String, dynamic>? user;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = true,
    this.user,
    this.error,
  });

  AuthState copyWith({bool? isAuthenticated, bool? isLoading, Map<String, dynamic>? user, String? error}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final token = await SecureStorage.getToken();
    if (token == null) return const AuthState(isAuthenticated: false, isLoading: false);

    // Verify token by fetching me
    try {
      final client = await ref.read(graphqlClientProvider.future);
      final result = await client.query(QueryOptions(document: gql(kMe)));
      if (result.hasException || result.data?['me'] == null) {
        await SecureStorage.clearTokens();
        return const AuthState(isAuthenticated: false, isLoading: false);
      }
      return AuthState(isAuthenticated: true, isLoading: false, user: result.data!['me']);
    } catch (_) {
      return const AuthState(isAuthenticated: false, isLoading: false);
    }
  }

  Future<bool> login(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      final client = await ref.read(graphqlClientProvider.future);
      final result = await client.mutate(MutationOptions(
        document: gql(kTokenAuth),
        variables: {'username': username, 'password': password},
      ));

      if (result.hasException) {
        state = AsyncValue.data(AuthState(isAuthenticated: false, isLoading: false, error: 'Invalid credentials.'));
        return false;
      }

      final data = result.data!['tokenAuth'];
      await SecureStorage.saveTokens(data['token'], data['refreshToken']);

      // Fetch user profile
      final meResult = await client.query(QueryOptions(document: gql(kMe)));
      final user = meResult.data?['me'];

      state = AsyncValue.data(AuthState(isAuthenticated: true, isLoading: false, user: user));
      return true;
    } catch (e) {
      state = AsyncValue.data(AuthState(isAuthenticated: false, isLoading: false, error: e.toString()));
      return false;
    }
  }

  Future<bool> register(String username, String email, String password, {String? phone}) async {
    state = const AsyncValue.loading();
    try {
      final client = await ref.read(graphqlClientProvider.future);
      final result = await client.mutate(MutationOptions(
        document: gql(kRegister),
        variables: {'username': username, 'email': email, 'password': password, 'phone': phone},
      ));

      if (result.hasException) {
        state = AsyncValue.data(AuthState(isAuthenticated: false, isLoading: false, error: 'Registration failed.'));
        return false;
      }

      final data = result.data!['register'];
      if (data['success'] != true) {
        final errors = (data['errors'] as List?)?.join(', ') ?? 'Registration failed.';
        state = AsyncValue.data(AuthState(isAuthenticated: false, isLoading: false, error: errors));
        return false;
      }

      await SecureStorage.saveTokens(data['token'], data['refreshToken']);
      state = AsyncValue.data(const AuthState(isAuthenticated: true, isLoading: false));
      return true;
    } catch (e) {
      state = AsyncValue.data(AuthState(isAuthenticated: false, isLoading: false, error: e.toString()));
      return false;
    }
  }

  Future<void> logout() async {
    await SecureStorage.clearTokens();
    state = const AsyncValue.data(AuthState(isAuthenticated: false, isLoading: false));
  }

  void clearError() {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(error: null));
    }
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
