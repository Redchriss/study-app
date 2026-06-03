import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class AiTutorConfidenceBadge extends StatelessWidget {
  final String label;
  const AiTutorConfidenceBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final isLow = label == 'Low confidence' || label == 'Uncertain';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isLow ? DesignTokens.warning : DesignTokens.info)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: (isLow ? DesignTokens.warning : DesignTokens.info)
              .withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLow ? Icons.help_outline : Icons.check_circle_outline,
            size: 10,
            color: isLow ? DesignTokens.warning : DesignTokens.info,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isLow ? DesignTokens.warning : DesignTokens.info,
            ),
          ),
        ],
      ),
    );
  }
}

class AiTutorFeedbackButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const AiTutorFeedbackButton({
    super.key,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive
          ? DesignTokens.primary.withValues(alpha: 0.1)
          : Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 14,
            color: isActive ? DesignTokens.primary : DesignTokens.textTertiary,
          ),
        ),
      ),
    );
  }
}

class AiTutorReportBottomSheet extends StatelessWidget {
  final void Function(String?)? onFeedback;

  const AiTutorReportBottomSheet({super.key, this.onFeedback});

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
            const Text('Report this response',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('What\'s wrong?',
                style:
                    TextStyle(fontSize: 13, color: DesignTokens.textSecondary)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.error_outline),
              title: const Text('Factually incorrect'),
              onTap: () {
                Navigator.pop(context);
                onFeedback?.call('report');
              },
            ),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text('Not helpful for learning'),
              onTap: () {
                Navigator.pop(context);
                onFeedback?.call('report');
              },
            ),
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text('Inappropriate'),
              onTap: () {
                Navigator.pop(context);
                onFeedback?.call('report');
              },
            ),
            ListTile(
              leading: const Icon(Icons.more_horiz),
              title: const Text('Other issue'),
              onTap: () {
                Navigator.pop(context);
                onFeedback?.call('report');
              },
            ),
          ],
        ),
      ),
    );
  }
}
