import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/design_tokens.dart';

class ForgotPasswordSheet extends ConsumerStatefulWidget {
  const ForgotPasswordSheet({super.key});

  @override
  ConsumerState<ForgotPasswordSheet> createState() =>
      _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<ForgotPasswordSheet> {
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DesignTokens.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DesignTokens.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_reset_rounded,
                size: 36, color: DesignTokens.primary),
          ),
          const SizedBox(height: 20),
          Text('Reset Password',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            'Enter your email address and we\'ll send you a link to reset your password.',
            style: TextStyle(
                color: DesignTokens.textSecondary, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 24),
          if (!_sent)
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _send(),
            ),
          if (!_sent) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _send,
                child: const Text('Send Reset Link'),
              ),
            ),
          ],
          if (_sent)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DesignTokens.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: DesignTokens.success.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: DesignTokens.success),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Check your inbox at ${_emailCtrl.text.trim()}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _send() {
    if (_emailCtrl.text.trim().isEmpty || !_emailCtrl.text.contains('@'))
      return;
    HapticFeedback.lightImpact();
    setState(() => _sent = true);
  }
}

void showForgotPasswordSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const ForgotPasswordSheet(),
  );
}
