import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import 'material_reader_models.dart';

Future<void> showReaderFlashcardsSheet(
  BuildContext context, {
  required List<ReaderFlashcardData> flashcards,
  required VoidCallback onGenerate,
  required bool isGenerating,
  String? helperText,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ReaderFlashcardsSheet(
      flashcards: flashcards,
      onGenerate: onGenerate,
      isGenerating: isGenerating,
      helperText: helperText,
    ),
  );
}

class _ReaderFlashcardsSheet extends StatefulWidget {
  const _ReaderFlashcardsSheet({
    required this.flashcards,
    required this.onGenerate,
    required this.isGenerating,
    this.helperText,
  });

  final List<ReaderFlashcardData> flashcards;
  final VoidCallback onGenerate;
  final bool isGenerating;
  final String? helperText;

  @override
  State<_ReaderFlashcardsSheet> createState() => _ReaderFlashcardsSheetState();
}

class _ReaderFlashcardsSheetState extends State<_ReaderFlashcardsSheet> {
  var _index = 0;
  var _revealed = false;

  @override
  Widget build(BuildContext context) {
    final hasCards = widget.flashcards.isNotEmpty;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reader Flashcards',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (!hasCards) ...[
              Text(
                widget.helperText ??
                    'Generate a flashcard deck from this material and revise it inside study mode.',
                style: const TextStyle(
                    color: DesignTokens.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.isGenerating ? null : widget.onGenerate,
                  icon: widget.isGenerating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.psychology_rounded),
                  label: Text(widget.isGenerating
                      ? 'Generating...'
                      : 'Generate Flashcards'),
                ),
              ),
            ] else ...[
              Text('${_index + 1} of ${widget.flashcards.length}',
                  style: const TextStyle(color: DesignTokens.textSecondary)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => setState(() => _revealed = !_revealed),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Container(
                    key: ValueKey('${_index}_$_revealed'),
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _revealed
                            ? const [Color(0xFF0F4C5C), Color(0xFF16596D)]
                            : const [Color(0xFFF6E4B2), Color(0xFFEDC86E)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_revealed ? 'Back' : 'Front',
                            style: TextStyle(
                                color:
                                    _revealed ? Colors.white70 : Colors.black54,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 16),
                        Text(
                          _revealed
                              ? widget.flashcards[_index].back
                              : widget.flashcards[_index].front,
                          style: TextStyle(
                              color: _revealed ? Colors.white : Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              height: 1.4),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _revealed
                              ? 'Tap again to return to the prompt.'
                              : 'Tap to reveal the answer.',
                          style: TextStyle(
                              color:
                                  _revealed ? Colors.white70 : Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _index == 0
                          ? null
                          : () => setState(() {
                                _index -= 1;
                                _revealed = false;
                              }),
                      child: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _index == widget.flashcards.length - 1
                          ? null
                          : () => setState(() {
                                _index += 1;
                                _revealed = false;
                              }),
                      child: const Text('Next'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
