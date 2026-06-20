import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/design_tokens.dart';
import '../widgets/agent_bubbles.dart';

class AgentStreamingMessage extends StatelessWidget {
  final String text;
  final Animation<double> cursorAnim;
  final Animation<double> breathAnim;
  final bool dark;

  const AgentStreamingMessage({
    super.key,
    required this.text,
    required this.cursorAnim,
    required this.breathAnim,
    required this.dark,
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
            child: ScaleTransition(
              scale: breathAnim,
              child: const Icon(Icons.psychology_rounded,
                  color: Colors.white, size: 14),
            ),
          ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78),
              margin: const EdgeInsets.only(bottom: 10, right: 48),
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
              child: Stack(
                children: [
                  MarkdownBody(
                    data: sanitizeStreamingMarkdown(text),
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 14, height: 1.55),
                      code: TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                          backgroundColor:
                              dark ? Colors.black26 : const Color(0xFFEEF0F2)),
                      codeblockDecoration: BoxDecoration(
                          color: dark
                              ? const Color(0xFF161B22)
                              : const Color(0xFFEEF0F2),
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: ScaleTransition(
                      scale: breathAnim,
                      child: FadeTransition(
                        opacity: cursorAnim,
                        child: Container(
                          width: 8,
                          height: 16,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF7C4DFF),
                                Color(0xFF1B6CA8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
