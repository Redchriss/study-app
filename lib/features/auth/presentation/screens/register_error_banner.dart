import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class RegisterErrorBanner extends StatelessWidget {
  final String message;

  const RegisterErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DesignTokens.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DesignTokens.error.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: DesignTokens.error,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: DesignTokens.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
