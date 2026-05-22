import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/design_tokens.dart';

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

  const AiAssistantBubble({
    super.key,
    required this.text,
    required this.streaming,
    required this.cursorAnim,
    required this.dark,
    this.feedback,
    this.onFeedback,
  });

  @override
  Widget build(BuildContext context) {
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
            child: const Icon(Icons.auto_awesome_rounded,
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
                              data: text,
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
                                child: FadeTransition(
                                  opacity: cursorAnim,
                                  child: Container(
                                      width: 8,
                                      height: 16,
                                      decoration: BoxDecoration(
                                          color: const Color(0xFF7C4DFF),
                                          borderRadius:
                                              BorderRadius.circular(2))),
                                ),
                              ),
                          ],
                        ),
                ),
                if (!streaming && text.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _FeedbackButton(
                        icon: Icons.thumb_up_alt_rounded,
                        isActive: feedback == 'like',
                        onTap: () => onFeedback
                            ?.call(feedback == 'like' ? null : 'like'),
                      ),
                      _FeedbackButton(
                        icon: Icons.thumb_down_alt_rounded,
                        isActive: feedback == 'dislike',
                        onTap: () => onFeedback
                            ?.call(feedback == 'dislike' ? null : 'dislike'),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        iconSize: 14,
                        icon: const Icon(Icons.copy_rounded),
                        color: DesignTokens.textTertiary,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: const Text('Copied to clipboard'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                duration: const Duration(seconds: 1)),
                          );
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(begin: -0.05);
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
