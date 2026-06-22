import '../../../../core/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../kids_visual_theme.dart';
import 'kid_auth_pin_data.dart';
import 'kid_graphical_pin_grid.dart';
import 'kid_numeric_pin_pad.dart';
export 'kid_auth_state.dart';

class KidPinDialog extends StatefulWidget {
  const KidPinDialog({
    super.key,
    required this.kidName,
    required this.onSubmit,
    this.graphical = false,
  });

  final String kidName;
  final Future<void> Function(String) onSubmit;
  final bool graphical;

  @override
  State<KidPinDialog> createState() => _KidPinDialogState();
}

class _KidPinDialogState extends State<KidPinDialog> {
  final _pin = <String>[];

  void _press(String d) {
    if (_pin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() => _pin.add(d));
    if (_pin.length == 4) widget.onSubmit(_pin.join(''));
  }

  void _delete() {
    if (_pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _pin.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        label: 'PIN entry dialog',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(gradient: KidsVisualTheme.ctaGradient),
              child: Column(
                children: [
                  Semantics(
                    header: true,
                    child: Text('Hi, ${widget.kidName}!',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.graphical
                        ? 'Tap the pictures in order'
                        : 'Enter your secret PIN',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    label: 'PIN digits entered: ${_pin.length} of 4',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                          4,
                          (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                curve: Curves.easeOutBack,
                                width: 52,
                                height: 52,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  color: i < _pin.length
                                      ? KidsVisualTheme.trailGreen
                                      : DesignTokens.border,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: i < _pin.length
                                          ? Colors.white
                                          : DesignTokens.textTertiary,
                                      width: 2),
                                  boxShadow: i < _pin.length
                                      ? [
                                          BoxShadow(
                                              color: KidsVisualTheme.trailGreen
                                                  .withValues(alpha: 0.35),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3))
                                        ]
                                      : null,
                                ),
                                child: Center(
                                    child: Semantics(
                                  excludeSemantics: true,
                                  child: Text(i < _pin.length
                                      ? (widget.graphical
                                          ? pinEmojis[_pin[i].isEmpty
                                              ? 0
                                              : int.tryParse(_pin[i]) != null
                                                  ? int.parse(_pin[i]) - 1
                                                  : 0]
                                          : '\u2022')
                                      : '\u25CB'),
                                )),
                              )),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (widget.graphical)
                    GraphicalPinGrid(
                      onEmojiTap: (emoji) => _press(emojiPinMap[emoji]!),
                      delete: _delete,
                    )
                  else
                    NumericPinPad(
                      onDigit: _press,
                      onDelete: _delete,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
