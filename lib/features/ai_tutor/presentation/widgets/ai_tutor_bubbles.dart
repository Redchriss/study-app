import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/design_tokens.dart';

String sanitizeStreamingMarkdown(String text) {
  final codeFences = '```'.allMatches(text).length;
  if (codeFences.isOdd) text += '\n```';
  final boldMarkers = '**'.allMatches(text).length;
  if (boldMarkers.isOdd) text += '**';
  final italicMarkers = RegExp(r'(?<!\*)\*(?!\*)').allMatches(text).length;
  if (italicMarkers.isOdd) text += ' _';
  final tableSep = RegExp(r'\|[-| ]+\|').allMatches(text).length;
  if (tableSep > 0 && !text.endsWith('|\n')) text += '\n';
  return text;
}

String _extractConfidenceLabel(String text) {
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

class AiUserBubble extends StatelessWidget {
  final String text;
  const AiUserBubble({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: 10, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          gradient:
              LinearGradient(colors: [Color(0xFF1B6CA8), Color(0xFF7C4DFF)]),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, height: 1.5)),
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.1);
  }
}

class AiAssistantBubble extends StatelessWidget {
  final String text;
  final bool streaming;
  final Animation<double> cursorAnim;
  final bool dark;
  final String? feedback;
  final void Function(String?)? onFeedback;
  final VoidCallback? onRetry;

  const AiAssistantBubble({
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
    final confidenceLabel = !streaming ? _extractConfidenceLabel(text) : '';
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
                : const Icon(Icons.auto_awesome_rounded,
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
                          _ConfidenceBadge(label: confidenceLabel),
                        if (confidenceLabel.isNotEmpty)
                          const SizedBox(width: 6),
                        _FeedbackButton(
                          icon: Icons.thumb_up_alt_rounded,
                          isActive: feedback == 'like',
                          onTap: () => onFeedback
                              ?.call(feedback == 'like' ? null : 'like'),
                        ),
                        const SizedBox(width: 2),
                        _FeedbackButton(
                          icon: Icons.thumb_down_alt_rounded,
                          isActive: feedback == 'dislike',
                          onTap: () => onFeedback
                              ?.call(feedback == 'dislike' ? null : 'dislike'),
                        ),
                        const SizedBox(width: 2),
                        _FeedbackButton(
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
      builder: (ctx) => SafeArea(
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
                  style: TextStyle(
                      fontSize: 13, color: DesignTokens.textSecondary)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.error_outline),
                title: const Text('Factually incorrect'),
                onTap: () {
                  Navigator.pop(ctx);
                  onFeedback?.call('report');
                },
              ),
              ListTile(
                leading: const Icon(Icons.school_outlined),
                title: const Text('Not helpful for learning'),
                onTap: () {
                  Navigator.pop(ctx);
                  onFeedback?.call('report');
                },
              ),
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: const Text('Inappropriate'),
                onTap: () {
                  Navigator.pop(ctx);
                  onFeedback?.call('report');
                },
              ),
              ListTile(
                leading: const Icon(Icons.more_horiz),
                title: const Text('Other issue'),
                onTap: () {
                  Navigator.pop(ctx);
                  onFeedback?.call('report');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final String label;
  const _ConfidenceBadge({required this.label});

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

class _FeedbackButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _FeedbackButton({
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
