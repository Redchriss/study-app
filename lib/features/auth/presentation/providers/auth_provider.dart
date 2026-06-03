import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/graphql/client.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/storage/secure_storage.dart';
import 'auth_state.dart';
export 'auth_state.dart';

part 'auth_login_mixin.dart';
part 'auth_register_mixin.dart';
part 'auth_delete_account_mixin.dart';

final graphqlClientProvider = Provider<GraphQLClient>((ref) {
  return buildGraphQLClient();
});

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState>
    with AuthLoginMixin, AuthRegisterMixin, AuthDeleteAccountMixin {
  Timer? _refreshTimer;

  @override
  AuthState build() {
    ref.onDispose(() => _refreshTimer?.cancel());
    _bootstrap();
    return const AuthState(isAuthenticated: false, isLoading: true);
  }

  @override
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
        // Only clear tokens on explicit auth error, not network failures
        final isAuthError = result.exception?.graphqlErrors.any((e) =>
                e.message.toLowerCase().contains('not authenticated') ||
                e.message.toLowerCase().contains('permission') ||
                e.message.toLowerCase().contains('unauthorized')) ==
            true;
        if (isAuthError) await SecureStorage.clearTokens();
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

  /// Bootstrap without toggling isLoading (used after login/register so the
  /// router doesn't flash back to /splash mid-submit).
  @override
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
        final isAuthError = result.exception?.graphqlErrors.any((e) =>
                e.message.toLowerCase().contains('not authenticated') ||
                e.message.toLowerCase().contains('permission') ||
                e.message.toLowerCase().contains('unauthorized')) ==
            true;
        if (isAuthError) await SecureStorage.clearTokens();
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

  @override
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
        state = AuthState(
            isAuthenticated: true, isLoading: false, user: result.data!['me']);
      }
    } catch (e) {
      debugPrint('refreshUser failed: $e');
    }
  }
}
