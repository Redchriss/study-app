import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/design_tokens.dart';

class RegisterStepUsername extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final bool dark;
  final VoidCallback onContinue;

  const RegisterStepUsername({
    super.key,
    required this.formKey,
    required this.controller,
    required this.dark,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DesignTokens.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline_rounded,
                  size: 40, color: DesignTokens.primary),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text(
              'What should we\ncall you?',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
            const SizedBox(height: 12),
            const Text(
              'Your unique username on Yaza.',
              style: TextStyle(
                  fontSize: 15,
                  color: DesignTokens.textSecondary,
                  fontWeight: FontWeight.w500),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            const SizedBox(height: 40),
            TextFormField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: const Icon(Icons.alternate_email_rounded),
                hintText: 'e.g. kondwani265',
                filled: true,
                fillColor: dark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onContinue(),
              validator: (v) {
                if (v == null || v.trim().isEmpty)
                  return 'Username is required';
                if (v.trim().length < 3) return 'At least 3 characters';
                if (v.trim().contains(' ')) return 'No spaces allowed';
                return null;
              },
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }
}
