import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../kids_visual_theme.dart';
import 'interactive_match_data.dart';

class InteractiveMatchWidget extends StatefulWidget {
  final InteractiveMatchData data;
  final VoidCallback onCorrect;

  const InteractiveMatchWidget({required this.data, required this.onCorrect});

  @override
  State<InteractiveMatchWidget> createState() => InteractiveMatchWidgetState();
}

class InteractiveMatchWidgetState extends State<InteractiveMatchWidget> {
  int? _selectedIndex;
  bool _isSuccess = false;

  void _handleTap(int index) {
    if (_isSuccess) return;

    setState(() {
      _selectedIndex = index;
    });

    if (index == widget.data.correctIndex) {
      HapticFeedback.heavyImpact();
      setState(() {
        _isSuccess = true;
      });
      Future.delayed(const Duration(milliseconds: 500), widget.onCorrect);
    } else {
      HapticFeedback.vibrate();
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted && !_isSuccess) {
          setState(() {
            _selectedIndex = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Interactive match: ${widget.data.question}',
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: KidsVisualTheme.trailGreen.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: KidsVisualTheme.trailGreen, width: 3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Semantics(
              header: true,
              child: Text(
                widget.data.question,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: KidsVisualTheme.ink,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(widget.data.options.length, (index) {
                final isSelected = _selectedIndex == index;
                final isCorrect =
                    isSelected && index == widget.data.correctIndex;
                final isWrong = isSelected && index != widget.data.correctIndex;

                return Semantics(
                  button: true,
                  label:
                      '${widget.data.options[index].label}: ${widget.data.options[index].emoji}',
                  child: GestureDetector(
                    onTap: () => _handleTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? KidsVisualTheme.trailGreen
                            : (isWrong ? Colors.redAccent : Colors.white),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: isSelected ? 0 : 8,
                            offset: Offset(0, isSelected ? 0 : 4),
                          )
                        ],
                        border: Border.all(
                          color: isCorrect ? Colors.white : Colors.transparent,
                          width: 4,
                        ),
                      ),
                      child: Semantics(
                        excludeSemantics: true,
                        child: Text(
                          widget.data.options[index].emoji,
                          style: const TextStyle(fontSize: 42),
                        ),
                      ),
                    ).animate(target: isWrong ? 1 : 0).shake(
                        hz: 4, curve: Curves.easeInOutCubic, duration: 300.ms),
                  ),
                );
              }),
            ),
            if (_isSuccess) ...[
              const SizedBox(height: 20),
              Semantics(
                liveRegion: true,
                label: 'Great job, correct answer',
                child: const Text(
                  'Great Job!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: KidsVisualTheme.trailGreen,
                  ),
                ).animate().scale(curve: Curves.elasticOut),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
