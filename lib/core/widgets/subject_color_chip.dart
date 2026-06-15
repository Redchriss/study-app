import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// A gradient chip colored by subject.
/// Replaces the default ChoiceChip in the study hub filter bar
/// with subject-specific gradient colors.
class SubjectColorChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const SubjectColorChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DesignTokens.durFast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : color.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

/// A set of preset subject colors for Malawi's education system.
class SubjectColors {
  static const mathematics = Color(0xFFF4A261);
  static const english = Color(0xFF1B6CA8);
  static const science = Color(0xFF27AE60);
  static const chichewa = Color(0xFF2EC4B6);
  static const history = Color(0xFF7C4DFF);
  static const geography = Color(0xFFE87E5E);
  static const biology = Color(0xFF2ECC71);
  static const physics = Color(0xFF3498DB);
  static const chemistry = Color(0xFF9B59B6);
  static const social = Color(0xFFE74C3C);
  static const defaultColor = Color(0xFF95A5A6);

  static Color forName(String name) {
    switch (name.toLowerCase()) {
      case 'mathematics':
      case 'math':
      case 'maths':
        return mathematics;
      case 'english':
      case 'english language':
        return english;
      case 'science':
      case 'general science':
        return science;
      case 'chichewa':
        return chichewa;
      case 'history':
      case 'social studies':
        return history;
      case 'geography':
        return geography;
      case 'biology':
      case 'life science':
        return biology;
      case 'physics':
      case 'physical science':
        return physics;
      case 'chemistry':
        return chemistry;
      default:
        return defaultColor;
    }
  }
}
