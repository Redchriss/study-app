import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/design_tokens.dart';

class PasswordStrength {
  final int score;
  final String label;
  final Color color;
  final String? hint;

  const PasswordStrength(this.score, this.label, this.color, {this.hint});

  static PasswordStrength evaluate(String password) {
    if (password.isEmpty)
      return const PasswordStrength(0, '', Colors.transparent);
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[^A-Za-z0-9]'))) score++;

    if (score <= 1)
      return const PasswordStrength(1, 'Weak', DesignTokens.error,
          hint: 'Add uppercase, numbers & symbols');
    if (score <= 3)
      return const PasswordStrength(2, 'Fair', DesignTokens.warning,
          hint: 'Mix uppercase, numbers & symbols');
    if (score <= 4)
      return const PasswordStrength(3, 'Good', DesignTokens.info,
          hint: 'Almost there — add a symbol');
    return const PasswordStrength(4, 'Strong', DesignTokens.success,
        hint: 'Your password is secure');
  }
}

class RegisterStepPassword extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final bool dark;
  final VoidCallback onSubmit;

  const RegisterStepPassword({
    super.key,
    required this.formKey,
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.dark,
    required this.onSubmit,
  });

  @override
  State<RegisterStepPassword> createState() => _RegisterStepPasswordState();
}

class _RegisterStepPasswordState extends State<RegisterStepPassword> {
  bool _obscure = true;
  PasswordStrength _strength =
      const PasswordStrength(0, '', Colors.transparent);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: widget.formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6B48FF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_person_rounded,
                  size: 40, color: Color(0xFF6B48FF)),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text(
              'Secure your\naccount',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
            const SizedBox(height: 12),
            const Text(
              'Create a strong password to keep your study progress safe.',
              style: TextStyle(
                  fontSize: 15,
                  color: DesignTokens.textSecondary,
                  fontWeight: FontWeight.w500,
                  height: 1.4),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            const SizedBox(height: 40),
            TextFormField(
              controller: widget.passwordCtrl,
              autofocus: true,
              obscureText: _obscure,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                hintText: 'Min. 8 characters',
                filled: true,
                fillColor: widget.dark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                suffixIcon: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              textInputAction: TextInputAction.next,
              onChanged: (v) =>
                  setState(() => _strength = PasswordStrength.evaluate(v)),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 8)
                  return 'Password must be at least 8 characters';
                return null;
              },
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
            if (_strength.score > 0) ...[
              const SizedBox(height: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        for (int i = 0; i < 4; i++)
                          Expanded(
                            child: Container(
                              height: 4,
                              margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                              decoration: BoxDecoration(
                                color: i < _strength.score
                                    ? _strength.color
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          _strength.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _strength.color,
                          ),
                        ),
                        if (_strength.hint != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _strength.hint!,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: DesignTokens.textTertiary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: widget.confirmCtrl,
              obscureText: _obscure,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_reset_rounded),
                filled: true,
                fillColor: widget.dark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => widget.onSubmit(),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please confirm password';
                if (v != widget.passwordCtrl.text)
                  return 'Passwords do not match';
                return null;
              },
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }
}
