import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../../core/theme/design_tokens.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Passwords do not match'),
          backgroundColor: DesignTokens.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    final ok = await ref.read(authProvider.notifier).register(
      _usernameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
    );
    if (mounted) setState(() => _loading = false);
    if (!mounted) return;
    if (ok) {
      context.go('/setup');
    } else {
      final error = ref.read(authProvider).error ?? 'Registration failed.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: DesignTokens.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Top gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.30,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1F6A52), Color(0xFF0D3B2E)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 20, 32, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                            onPressed: () => context.go('/onboarding'),
                          ),
                          const Text(
                            'Yaza',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Create\naccount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          letterSpacing: -1.2,
                        ),
                      ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.3),
                      Text(
                        'Join thousands of Malawian students',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 14,
                        ),
                      ).animate(delay: 200.ms).fadeIn(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Form card
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.22),
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color ?? theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
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
                          Text(
                            'Your details',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ).animate(delay: 200.ms).fadeIn(),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _usernameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                              hintText: 'e.g. john_banda',
                            ),
                            textInputAction: TextInputAction.next,
                            validator: (v) =>
                                v!.length < 3 ? 'At least 3 characters' : null,
                          ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.15),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                              hintText: 'your@email.com',
                            ),
                            textInputAction: TextInputAction.next,
                            validator: (v) =>
                                !v!.contains('@') ? 'Enter a valid email' : null,
                          ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.15),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone (optional)',
                              prefixIcon: Icon(Icons.phone_outlined),
                              hintText: '+265 ...',
                            ),
                            textInputAction: TextInputAction.next,
                          ).animate(delay: 320.ms).fadeIn().slideY(begin: 0.15),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              hintText: 'Min. 8 characters',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            textInputAction: TextInputAction.next,
                            validator: (v) =>
                                v!.length < 8 ? 'At least 8 characters' : null,
                          ).animate(delay: 340.ms).fadeIn().slideY(begin: 0.15),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _confirmCtrl,
                            obscureText: _obscure,
                            decoration: const InputDecoration(
                              labelText: 'Confirm password',
                              prefixIcon: Icon(Icons.lock_outline_rounded),
                            ),
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            validator: (v) =>
                                v!.isEmpty ? 'Confirm your password' : null,
                          ).animate(delay: 360.ms).fadeIn().slideY(begin: 0.15),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ).animate(delay: 400.ms).fadeIn(),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: () => context.go('/login'),
                              child: RichText(
                                text: TextSpan(
                                  style: theme.textTheme.bodyMedium,
                                  children: [
                                    const TextSpan(
                                      text: 'Already have an account? ',
                                      style: TextStyle(
                                        color: DesignTokens.textSecondary,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Log in',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).animate(delay: 450.ms).fadeIn(),
                        ],
                      ),
                    ),
                  ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
