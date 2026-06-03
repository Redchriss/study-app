import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class AiTutorErrorBottomSheet extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  const AiTutorErrorBottomSheet({
    super.key,
    required this.error,
    required this.onRetry,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: DesignTokens.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.wifi_off_rounded, color: DesignTokens.error),
                const SizedBox(width: 8),
                Text('Connection lost',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            Text(error,
                style: const TextStyle(
                    color: DesignTokens.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onRetry();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onDismiss();
                },
                child: const Text('Dismiss'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
