import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/design_tokens.dart';

class ScannerResultsStepRow extends StatelessWidget {
  final int stepNum;
  final String text;
  final bool dark;

  const ScannerResultsStepRow(
      {super.key,
      required this.stepNum,
      required this.text,
      required this.dark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: DesignTokens.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                  color: DesignTokens.primary.withValues(alpha: 0.3)),
            ),
            child: Center(
                child: Text('$stepNum',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.primary))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: MarkdownBody(
              data: text,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: dark
                        ? DesignTokens.darkTextPrimary
                        : DesignTokens.textPrimary),
                code: TextStyle(
                    fontSize: 13,
                    backgroundColor: dark
                        ? DesignTokens.darkSurfaceVariant
                        : DesignTokens.surfaceVariant,
                    color: DesignTokens.primary,
                    fontFamily: 'monospace'),
                blockquoteDecoration: BoxDecoration(
                  border: Border(
                      left: BorderSide(color: DesignTokens.accent, width: 3)),
                  color: DesignTokens.accent.withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
