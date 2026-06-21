import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/design_tokens.dart';

/// Consistent empty state with animated icon, message, and optional action.
/// Use on every list screen instead of manual Center + Column.

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: DesignTokens.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 48,
                  color: DesignTokens.textTertiary.withValues(alpha: 0.5)),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.08, 1.08),
                  duration: 1200.ms,
                  curve: Curves.easeInOut,
                )
                .fadeIn(duration: 400.ms),
            const SizedBox(height: DesignTokens.spMd),
            Text(title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
            if (subtitle != null) ...[
              const SizedBox(height: DesignTokens.spXs),
              Text(subtitle!,
                  style: const TextStyle(color: DesignTokens.textSecondary),
                  textAlign: TextAlign.center),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: DesignTokens.spLg),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
