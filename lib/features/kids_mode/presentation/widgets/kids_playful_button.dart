import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../kids_visual_theme.dart';

/// Chunky primary action — readable at arm’s length, strong affordance (pressed depth).
class KidsPlayfulPrimaryButton extends StatefulWidget {
  const KidsPlayfulPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool enabled;

  @override
  State<KidsPlayfulPrimaryButton> createState() =>
      _KidsPlayfulPrimaryButtonState();
}

class _KidsPlayfulPrimaryButtonState extends State<KidsPlayfulPrimaryButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && widget.onTap != null;
    final translate = _down && active ? 2.0 : 0.0;
    return GestureDetector(
      onTapDown: (_) => active ? setState(() => _down = true) : null,
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: () {
        if (!active) return;
        HapticFeedback.lightImpact();
        widget.onTap!();
      },
      child: Transform.translate(
        offset: Offset(0, translate),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: active ? KidsVisualTheme.ctaGradient : null,
            color: active ? null : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(18),
            boxShadow: active
                ? KidsVisualTheme.chunkyShadow(const Color(0xFF2A8F4A),
                    dy: _down ? 1 : 4)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white, size: 22),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class KidsPlayfulSecondaryButton extends StatelessWidget {
  const KidsPlayfulSecondaryButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final active = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: active
            ? () {
                HapticFeedback.selectionClick();
                onTap!();
              }
            : null,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: active
                ? color.withValues(alpha: 0.14)
                : color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: color.withValues(alpha: active ? 0.45 : 0.15), width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: color.withValues(alpha: active ? 1 : 0.45), size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color.withValues(alpha: active ? 1 : 0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
