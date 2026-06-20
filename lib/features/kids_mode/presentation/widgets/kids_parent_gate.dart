import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../kids_visual_theme.dart';

/// A simple "parent gate" that blocks a young child from leaving Kids Mode on
/// their own. It asks an arithmetic question only an older child/adult can
/// answer quickly — the standard child-lock pattern — so we don't have to ship
/// the parent's secret PIN to the client.
class KidsParentGateChallenge {
  final int a;
  final int b;

  const KidsParentGateChallenge(this.a, this.b);

  factory KidsParentGateChallenge.random([Random? rng]) {
    final r = rng ?? Random();
    return KidsParentGateChallenge(6 + r.nextInt(7), 4 + r.nextInt(6));
  }

  int get answer => a + b;
  String get question => 'What is $a + $b?';

  bool isCorrect(String input) => int.tryParse(input.trim()) == answer;
}

/// Shows the parent gate and resolves to `true` only when the adult answers
/// the challenge correctly. Returns `false` on cancel/back.
Future<bool> showKidsParentGate(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _KidsParentGateDialog(),
  );
  return result ?? false;
}

class _KidsParentGateDialog extends StatefulWidget {
  const _KidsParentGateDialog();

  @override
  State<_KidsParentGateDialog> createState() => _KidsParentGateDialogState();
}

class _KidsParentGateDialogState extends State<_KidsParentGateDialog> {
  final _challenge = KidsParentGateChallenge.random();
  final _controller = TextEditingController();
  bool _error = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_challenge.isCorrect(_controller.text)) {
      Navigator.of(context).pop(true);
    } else {
      HapticFeedback.lightImpact();
      setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ask a grown-up'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Please answer to leave Kids Mode.'),
          const SizedBox(height: 12),
          Text(_challenge.question,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: KidsVisualTheme.ink)),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Type the answer',
              errorText: _error ? 'Try again' : null,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
