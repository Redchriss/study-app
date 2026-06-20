import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/design_tokens.dart';
import 'agent_bubbles.dart';
import 'agent_feedback_widgets.dart';

String extractConfidenceLabel(String text) {
  final match =
      RegExp(r'\[confidence:\s*(\d+(?:\.\d+)?)\s*\]').firstMatch(text);
  if (match == null) return '';
  final score = double.tryParse(match.group(1) ?? '') ?? 1.0;
  return score >= 0.9
      ? ''
      : score >= 0.7
          ? 'Likely'
          : score >= 0.5
              ? 'Uncertain'
              : 'Low confidence';
}

class AgentAssistantBubble extends StatelessWidget {
  final String text;
  final bool streaming;
  final Animation<double> cursorAnim;
  final bool dark;
  final String? feedback;
  final void Function(String?)? onFeedback;
  final VoidCallback? onRetry;

  const AgentAssistantBubble({
    super.key,
    required this.text,
    required this.streaming,
    required this.cursorAnim,
    required this.dark,
    this.feedback,
    this.onFeedback,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final confidenceLabel = !streaming ? extractConfidenceLabel(text) : '';
    final displayText = !streaming
        ? text.replaceAll(RegExp(r'\s*\[confidence:\s*[\d.]+\s*\]\s*'), '')
        : text;

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(right: 8, top: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF1B6CA8)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: streaming
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: Padding(
                      padding: EdgeInsets.all(7),
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: Colors.white),
                    ),
                  )
                : const Icon(Icons.psychology_rounded,
                    color: Colors.white, size: 14),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78),
                  margin: const EdgeInsets.only(bottom: 2, right: 48),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: dark
                        ? DesignTokens.darkSurfaceVariant
                        : DesignTokens.surfaceVariant,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  child: text.isEmpty && streaming
                      ? const SizedBox(
                          width: 40,
                          child: LinearProgressIndicator(minHeight: 2))
                      : Stack(
                          children: [
                            MarkdownBody(
                              data: streaming
                                  ? sanitizeStreamingMarkdown(displayText)
                                  : displayText,
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(fontSize: 14, height: 1.55),
                                code: TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                    backgroundColor: dark
                                        ? Colors.black26
                                        : const Color(0xFFEEF0F2)),
                                codeblockDecoration: BoxDecoration(
                                    color: dark
                                        ? const Color(0xFF161B22)
                                        : const Color(0xFFEEF0F2),
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            if (streaming)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: ScaleTransition(
                                  scale: cursorAnim,
                                  child: FadeTransition(
                                    opacity: cursorAnim,
                                    child: Container(
                                      width: 8,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF7C4DFF),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
                if (!streaming && displayText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (confidenceLabel.isNotEmpty)
                          AgentConfidenceBadge(label: confidenceLabel),
                        if (confidenceLabel.isNotEmpty)
                          const SizedBox(width: 6),
                        AgentFeedbackButton(
                          icon: Icons.thumb_up_alt_rounded,
                          isActive: feedback == 'like',
                          onTap: () => onFeedback
                              ?.call(feedback == 'like' ? null : 'like'),
                        ),
                        const SizedBox(width: 2),
                        AgentFeedbackButton(
                          icon: Icons.thumb_down_alt_rounded,
                          isActive: feedback == 'dislike',
                          onTap: () => onFeedback
                              ?.call(feedback == 'dislike' ? null : 'dislike'),
                        ),
                        const SizedBox(width: 2),
                        AgentFeedbackButton(
                          icon: Icons.feedback_rounded,
                          isActive: feedback == 'report',
                          onTap: () => _showReportOption(context),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          height: 28,
                          width: 28,
                          child: IconButton(
                            iconSize: 14,
                            icon: const Icon(Icons.copy_rounded),
                            color: DesignTokens.textTertiary,
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: displayText));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: const Text('Copied to clipboard'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    duration: const Duration(seconds: 1)),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(begin: -0.05);
  }

  void _showReportOption(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AgentReportBottomSheet(onFeedback: onFeedback),
    );
  }
}
