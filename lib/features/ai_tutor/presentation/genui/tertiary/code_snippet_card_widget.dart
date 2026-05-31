import 'package:flutter/material.dart';
import 'code_snippet_card_data.dart';

class CodeSnippetCardWidget extends StatefulWidget {
  final CodeSnippetCardData data;
  final void Function(int lineNumber, String lineContent) onLineTap;
  final VoidCallback onOutputReveal;

  const CodeSnippetCardWidget({
    super.key,
    required this.data,
    required this.onLineTap,
    required this.onOutputReveal,
  });

  @override
  State<CodeSnippetCardWidget> createState() => _CodeSnippetCardWidgetState();
}

class _CodeSnippetCardWidgetState extends State<CodeSnippetCardWidget>
    with SingleTickerProviderStateMixin {
  bool _showOutput = false;
  late final AnimationController _ctrl;
  late final Animation<double> _entrance;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entrance = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggleOutput() {
    setState(() => _showOutput = !_showOutput);
    if (!_showOutput) widget.onOutputReveal();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = widget.data.codeLines;

    return FadeTransition(
      opacity: _entrance,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade800,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.data.language,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (widget.data.conceptTag != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    widget.data.conceptTag!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(lines.length, (i) {
                  final lineNo = i + 1;
                  final annotation = widget.data.annotations
                      .where((a) => a.lineNumber == lineNo)
                      .firstOrNull;
                  return GestureDetector(
                    onTap: () => widget.onLineTap(lineNo, lines[i]),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text(
                              '$lineNo',
                              style: const TextStyle(
                                color: Color(0xFF858585),
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                  color: Color(0xFFD4D4D4),
                                  height: 1.5,
                                ),
                                children: [
                                  TextSpan(text: lines[i]),
                                  if (annotation != null)
                                    TextSpan(
                                      text: '  // ${annotation.note}',
                                      style: TextStyle(
                                        color: Colors.green.shade300,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _toggleOutput,
              icon: Icon(
                _showOutput ? Icons.visibility_off : Icons.play_arrow,
                size: 16,
              ),
              label: Text(
                _showOutput ? 'Hide output' : 'Predict output \u25b8',
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: _showOutput
                  ? Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.data.expectedOutput,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFFCE9178),
                          fontSize: 13,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
