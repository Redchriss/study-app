import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

/// A polished "tap to choose" selection field used in the profile-setup steps
/// (institution, programme, school) instead of the old flat grey `ListTile`.
///
/// Matches the level/number card aesthetic: rounded surface, gradient icon
/// chip, a label + chosen value (or placeholder), and a clear selected state.
class ProfileSelectionField extends StatelessWidget {
  const ProfileSelectionField({
    super.key,
    required this.icon,
    required this.label,
    required this.placeholder,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final IconData icon;

  /// Small caption above the value, e.g. "Institution".
  final String label;

  /// Text shown when nothing is selected yet.
  final String placeholder;

  /// The currently selected display value (null/empty when nothing chosen).
  final String? value;

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hasValue = value != null && value!.trim().isNotEmpty;
    return AnimatedPress(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DesignTokens.durFast,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dark ? DesignTokens.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
          border: Border.all(
            color: hasValue
                ? color.withValues(alpha: 0.5)
                : (dark ? DesignTokens.darkBorder : DesignTokens.border),
            width: hasValue ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: hasValue ? 0.12 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withValues(alpha: 0.85), color],
                ),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DesignTokens.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasValue ? value! : placeholder,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: hasValue ? null : DesignTokens.textTertiary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              hasValue
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              color: hasValue ? color : DesignTokens.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
