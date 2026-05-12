import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Spring-animated press wrapper — scales down on tap, bounces back.
/// Replace all raw GestureDetector buttons with this.

class AnimatedPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleTo;
  final Duration? duration;

  const AnimatedPress({
    super.key,
    required this.child,
    this.onTap,
    this.scaleTo = 0.96,
    this.duration,
  });

  @override
  State<AnimatedPress> createState() => _AnimatedPressState();
}

class _AnimatedPressState extends State<AnimatedPress>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.duration ?? DesignTokens.durNormal,
    );
    _anim = Tween<double>(begin: 1.0, end: widget.scaleTo).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    
    _ctrl.forward();
  }

  void _onTapUp(_) {
    
    _ctrl.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Transform.scale(
          scale: _anim.value,
          child: widget.child,
        ),
      ),
    );
  }
}
