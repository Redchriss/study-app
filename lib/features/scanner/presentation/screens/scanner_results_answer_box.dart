import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/design_tokens.dart';

class ScannerResultsAnswerBox extends StatelessWidget {
  final String answer;
  final bool dark;

  const ScannerResultsAnswerBox(
      {super.key, required this.answer, required this.dark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignTokens.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: DesignTokens.success.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline,
              color: DesignTokens.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Final Answer',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: DesignTokens.success,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4)),
                const SizedBox(height: 4),
                MarkdownBody(
                    data: answer,
                    styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: DesignTokens.success))),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.copy_outlined,
                size: 16, color: DesignTokens.textTertiary),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: answer));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Answer copied'),
                  duration: Duration(seconds: 1)));
            },
          ),
        ],
      ),
    );
  }
}
