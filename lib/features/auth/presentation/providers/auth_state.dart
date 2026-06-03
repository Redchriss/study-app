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
