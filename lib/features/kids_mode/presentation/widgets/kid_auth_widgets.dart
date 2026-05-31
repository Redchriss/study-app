import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../kids_visual_theme.dart';

// ── Auth State + Providers ────────────────────────────────────────────────────

class KidAuthState {
  final bool isAuthenticated;
  final String childName;
  final int standard;
  final String educationTrack;
  final String? token;
  const KidAuthState({
    this.isAuthenticated = false,
    this.childName = '',
    this.standard = 1,
    this.educationTrack = 'primary',
    this.token,
  });
}

final kidTokenProvider = StateProvider<String?>((ref) => null);
final kidProfileProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
final kidAuthStateProvider =
    StateProvider<KidAuthState>((ref) => const KidAuthState());

// ── Emoji-to-digit mapping for graphical PIN ─────────────────────────────────

const _emojiPinMap = {
  '🐶': '1',
  '🐱': '2',
  '🐰': '3',
  '🦁': '4',
  '🐸': '5',
  '🐵': '6',
  '🦊': '7',
  '🐼': '8',
  '🐨': '9',
};

const _pinEmojis = ['🐶', '🐱', '🐰', '🦁', '🐸', '🐵', '🦊', '🐼', '🐨'];

// ── PIN Dialog ────────────────────────────────────────────────────────────────

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
                                      : Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: i < _pin.length
                                          ? Colors.white
                                          : Colors.grey.shade400,
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
                                          ? _pinEmojis[_pin[i].isEmpty
                                              ? 0
                                              : int.tryParse(_pin[i]) != null
                                                  ? int.parse(_pin[i]) - 1
                                                  : 0]
                                          : '•')
                                      : '○'),
                                )),
                              )),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (widget.graphical)
                    _GraphicalPinGrid(
                      onEmojiTap: (emoji) => _press(_emojiPinMap[emoji]!),
                      delete: _delete,
                    )
                  else
                    _NumericPinPad(
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

// ── Graphical PIN Grid (ages 4-7) ──────────────────────────────────────────

class _GraphicalPinGrid extends StatelessWidget {
  const _GraphicalPinGrid({
    required this.onEmojiTap,
    required this.delete,
  });

  final void Function(String) onEmojiTap;
  final VoidCallback delete;

  @override
  Widget build(BuildContext context) {
    final emojiRows = [
      _pinEmojis.sublist(0, 3),
      _pinEmojis.sublist(3, 6),
      _pinEmojis.sublist(6, 9)
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: 'Emoji PIN pad',
          child: Column(
            children: emojiRows
                .map((row) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: row.map((emoji) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Semantics(
                              button: true,
                              label: 'Select ${_emojiPinMap[emoji]}',
                              child: Material(
                                color: Colors.grey.shade100,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () => onEmojiTap(emoji),
                                  child: SizedBox(
                                    width: 64,
                                    height: 64,
                                    child: Center(
                                      child: Semantics(
                                        excludeSemantics: true,
                                        child: Text(emoji,
                                            style:
                                                const TextStyle(fontSize: 30)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 4),
        Semantics(
          button: true,
          label: 'Delete last emoji',
          child: Material(
            color: Colors.orange,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: delete,
              child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Icon(Icons.backspace_outlined,
                      color: Colors.orange.shade800)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Numeric PIN Pad (ages 8+) — word + digit labels ─────────────────────────

class _NumericPinPad extends StatelessWidget {
  const _NumericPinPad({
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
                              color: Colors.grey.shade100,
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
                  color: Colors.grey.shade100,
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
