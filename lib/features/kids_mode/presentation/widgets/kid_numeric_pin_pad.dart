import '../../../../core/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import '../../kids_visual_theme.dart';

class NumericPinPad extends StatelessWidget {
  const NumericPinPad({
    required this.onDigit,
    required this.onDelete,
  });

  final void Function(String) onDigit;
  final VoidCallback onDelete;

  static const _wordMap = {
    '1': 'ONE',
    '2': 'TWO',
    '3': 'THREE',
    '4': 'FOUR',
    '5': 'FIVE',
    '6': 'SIX',
    '7': 'SEVEN',
    '8': 'EIGHT',
    '9': 'NINE',
    '0': 'ZERO',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...['123', '456', '789'].map((row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row
                    .split('')
                    .map((d) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Semantics(
                            button: true,
                            label: '${_wordMap[d]} $d',
                            child: Material(
                              color: DesignTokens.surfaceVariant,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => onDigit(d),
                                child: SizedBox(
                                    width: 72,
                                    height: 72,
                                    child: Center(
                                        child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(d,
                                            style: const TextStyle(
                                                fontSize: 26,
                                                fontWeight: FontWeight.w800)),
                                        Text(_wordMap[d]!,
                                            style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color:
                                                    KidsVisualTheme.inkMuted)),
                                      ],
                                    ))),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            )),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Semantics(
                button: true,
                label: 'ZERO 0',
                child: Material(
                  color: DesignTokens.surfaceVariant,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => onDigit('0'),
                    child: SizedBox(
                        width: 72,
                        height: 72,
                        child: Center(
                            child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('0',
                                style: TextStyle(
                                    fontSize: 26, fontWeight: FontWeight.w800)),
                            Text(_wordMap['0']!,
                                style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: KidsVisualTheme.inkMuted)),
                          ],
                        ))),
                  ),
                ),
              ),
            ),
            Semantics(
              button: true,
              label: 'Delete last digit',
              child: Material(
                color: Colors.orange,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onDelete,
                  child: SizedBox(
                      width: 72,
                      height: 72,
                      child: Icon(Icons.backspace_outlined,
                          color: Colors.orange.shade800)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
