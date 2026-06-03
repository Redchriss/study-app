import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class ModmailMessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool dark;

  const ModmailMessageBubble({
    super.key,
    required this.message,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final author = message['author'] as Map<String, dynamic>?;
    final isInternal = message['isInternal'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isInternal
            ? DesignTokens.warning.withValues(alpha: 0.08)
            : (dark ? DesignTokens.darkSurface : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isInternal
              ? DesignTokens.warning.withValues(alpha: 0.2)
              : (dark ? DesignTokens.darkBorder : DesignTokens.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('u/${author?['username'] ?? 'unknown'}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              if (isInternal) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: DesignTokens.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('INTERNAL',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: DesignTokens.warning)),
                ),
              ],
              const Spacer(),
              Text(timeAgo(message['createdAt']?.toString() ?? ''),
                  style: const TextStyle(
                      fontSize: 11, color: DesignTokens.textTertiary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(message['body']?.toString() ?? '',
              style: const TextStyle(fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }
}

String timeAgo(String iso) {
  try {
    final dt = DateTime.parse(iso);
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${diff.inDays ~/ 7}w ago';
  } catch (_) {
    return '';
  }
}
