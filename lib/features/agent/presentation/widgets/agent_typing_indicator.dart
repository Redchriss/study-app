import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class AgentTypingIndicator extends StatelessWidget {
  final int freeRemaining;
  const AgentTypingIndicator({super.key, this.freeRemaining = -1});

  @override
  Widget build(BuildContext context) {
    return _AgentTypingBody(freeRemaining: freeRemaining);
  }
}

class _AgentTypingBody extends StatefulWidget {
  final int freeRemaining;
  const _AgentTypingBody({required this.freeRemaining});

  @override
  State<_AgentTypingBody> createState() => _AgentTypingBodyState();
}

class _AgentTypingBodyState extends State<_AgentTypingBody> {
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
          if (widget.freeRemaining >= 0) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.freeRemaining > 0
                    ? DesignTokens.primary.withValues(alpha: 0.08)
                    : DesignTokens.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                widget.freeRemaining > 0
                    ? '$widget.freeRemaining free left'
                    : 'Credits',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: widget.freeRemaining > 0
                      ? DesignTokens.primary
                      : DesignTokens.warning,
                ),
              ),
            ),
          ],
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
