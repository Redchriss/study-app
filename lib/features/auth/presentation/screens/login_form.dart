import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../providers/auth_provider.dart';
import 'forgot_password_sheet.dart';
import 'login_biometric_tile.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  String? _fieldError;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _fieldError = null);
    final ok = await ref.read(authProvider.notifier).login(
          _usernameCtrl.text.trim(),
          _passwordCtrl.text,
        );
    if (!mounted) return;
    if (ok) {
      await _offerBiometric();
      return;
    }
    final error = ref.read(authProvider).error ??
        'Login failed. Please check your credentials.';
    HapticFeedback.mediumImpact();
    setState(() => _fieldError = error);
  }

  void _clearFieldError() {
    if (_fieldError == null) return;
    setState(() => _fieldError = null);
  }

  Future<void> _offerBiometric() async {
    final biometricService = BiometricService();
    final bioAvailable = await biometricService.isAvailable();
    final bioEnabled = await biometricService.isEnabled();
    if (!mounted || !bioAvailable || bioEnabled) return;
    final enable = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enable quick unlock?'),
        content: const Text(
          'Use this phone\'s Face ID or fingerprint after you log in.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Skip')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enable')),
        ],
      ),
    );
    if (enable == true && mounted) {
      await biometricService.setEnabled(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSubmitting = ref.watch(authProvider).isSubmitting;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sign In',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            if (_fieldError != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DesignTokens.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: DesignTokens.error.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: DesignTokens.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _fieldError!,
                        style: const TextStyle(
                            color: DesignTokens.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            TextFormField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(
                labelText: 'Username or Email',
                prefixIcon: Icon(Icons.person_outline_rounded),
                hintText: 'Enter your username or email',
              ),
              textInputAction: TextInputAction.next,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              onChanged: (_) => _clearFieldError(),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter your username' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              textInputAction: TextInputAction.done,
              onChanged: (_) => _clearFieldError(),
              onFieldSubmitted: (_) => _submit(),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Enter your password' : null,
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => showForgotPasswordSheet(context),
                style: TextButton.styleFrom(
                    foregroundColor: DesignTokens.textSecondary,
                    padding: EdgeInsets.zero),
                child: const Text('Forgot password?',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Log In',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
            const LoginBiometricTile(),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => context.go('/register'),
                child: Text.rich(
                  TextSpan(
                    style: theme.textTheme.bodyMedium,
                    children: [
                      const TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(color: DesignTokens.textSecondary)),
                      TextSpan(
                          text: 'Sign up',
                          style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
