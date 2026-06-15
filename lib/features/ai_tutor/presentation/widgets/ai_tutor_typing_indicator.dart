import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class AiTypingIndicator extends StatefulWidget {
  const AiTypingIndicator({super.key});

  @override
  State<AiTypingIndicator> createState() => _AiTypingIndicatorState();
}

class _AiTypingIndicatorState extends State<AiTypingIndicator> {
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _hint {
    if (_seconds < 10) return 'Thinking...';
    if (_seconds < 25) return 'Working on it...';
    if (_seconds < 45) return 'Almost there...';
    return 'Taking a bit longer than usual...';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF1B6CA8)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.psychology_rounded,
                color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: DesignTokens.surfaceVariant,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AiBouncingDot(delay: 0),
                const SizedBox(width: 4),
                const AiBouncingDot(delay: 200),
                const SizedBox(width: 4),
                const AiBouncingDot(delay: 400),
                const SizedBox(width: 8),
                Text(_hint,
                    style: const TextStyle(
                        fontSize: 12,
                        color: DesignTokens.textSecondary,
                        fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AiBouncingDot extends StatefulWidget {
  final int delay;
  const AiBouncingDot({super.key, required this.delay});

  @override
  State<AiBouncingDot> createState() => _AiBouncingDotState();
}

class _AiBouncingDotState extends State<AiBouncingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = Tween<double>(begin: 0, end: -6)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
                color: const Color(0xFF7C4DFF).withValues(alpha: 0.6),
                shape: BoxShape.circle)),
      ),
    );
  }
}
