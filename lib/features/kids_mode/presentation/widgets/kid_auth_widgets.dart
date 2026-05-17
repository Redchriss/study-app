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
final kidAuthStateProvider = StateProvider<KidAuthState>((ref) => const KidAuthState());

// ── PIN Dialog ────────────────────────────────────────────────────────────────

class KidPinDialog extends StatefulWidget {
  const KidPinDialog({super.key, required this.kidName, required this.onSubmit});

  final String kidName;
  final Future<void> Function(String) onSubmit;

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(gradient: KidsVisualTheme.ctaGradient),
            child: Column(
              children: [
                Text('Hi, ${widget.kidName}!', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('Enter your secret PIN', style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutBack,
                    width: 52, height: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: i < _pin.length ? KidsVisualTheme.trailGreen : Colors.grey.shade200,
                      shape: BoxShape.circle,
                      border: Border.all(color: i < _pin.length ? Colors.white : Colors.grey.shade400, width: 2),
                      boxShadow: i < _pin.length ? [BoxShadow(color: KidsVisualTheme.trailGreen.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))] : null,
                    ),
                    child: Center(child: Text(i < _pin.length ? '•' : '○', style: TextStyle(color: i < _pin.length ? Colors.white : Colors.grey.shade500, fontSize: 22, fontWeight: FontWeight.w800))),
                  )),
                ),
                const SizedBox(height: 20),
                ...['123', '456', '789'].map((row) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: row.split('').map((d) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Material(
                        color: Colors.grey.shade100,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _press(d),
                          child: SizedBox(width: 64, height: 64, child: Center(child: Text(d, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)))),
                        ),
                      ),
                    )).toList(),
                  ),
                )),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 76),
                    Material(
                      color: Colors.grey.shade100,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _press('0'),
                        child: const SizedBox(width: 64, height: 64, child: Center(child: Text('0', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)))),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Material(
                        color: Colors.orange,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _delete,
                          child: SizedBox(width: 64, height: 64, child: Icon(Icons.backspace_outlined, color: Colors.orange.shade800)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
