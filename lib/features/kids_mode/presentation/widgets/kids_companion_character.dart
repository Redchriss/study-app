import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'kids_companion_enums.dart';
import 'kids_companion_flame.dart';
import 'kids_companion_sprout.dart';
export 'kids_companion_enums.dart';

class KidsCompanionCharacter extends StatefulWidget {
  const KidsCompanionCharacter({
    super.key,
    this.type = CompanionType.sprout,
    this.mood = CompanionMood.idle,
    this.size = 80,
  });

  final CompanionType type;
  final CompanionMood mood;
  final double size;

  @override
  State<KidsCompanionCharacter> createState() => _KidsCompanionCharacterState();
}

class _KidsCompanionCharacterState extends State<KidsCompanionCharacter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(KidsCompanionCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mood == CompanionMood.celebration &&
        oldWidget.mood != widget.mood) {
      _ctrl.repeat(period: const Duration(milliseconds: 300), reverse: true);
    } else if (widget.mood != CompanionMood.celebration) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.type == CompanionType.sprout
          ? 'Sprout the plant companion'
          : 'Flame the fire companion',
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final idleBob = math.sin(_ctrl.value * math.pi) * 4;
          final celebrationScale = widget.mood == CompanionMood.celebration
              ? 1.0 + _ctrl.value * 0.15
              : 1.0;
          return Transform.translate(
            offset: Offset(0, -idleBob),
            child: Transform.scale(
              scale: celebrationScale,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: widget.type == CompanionType.sprout
                    ? SproutBody(mood: widget.mood, animValue: _ctrl.value)
                    : FlameBody(mood: widget.mood, animValue: _ctrl.value),
              ),
            ),
          );
        },
      ),
    );
  }
}

class KidsCompanionMessage extends StatelessWidget {
  const KidsCompanionMessage({
    super.key,
    required this.message,
    this.type = CompanionType.sprout,
  });

  final String message;
  final CompanionType type;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            KidsCompanionCharacter(type: type, size: 32),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF15324A),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
