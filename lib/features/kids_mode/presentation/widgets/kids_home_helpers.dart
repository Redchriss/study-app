import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../kids_visual_theme.dart';
import 'kid_auth_widgets.dart';

Color kidsSubjectColor(String name) {
  switch (name.toLowerCase()) {
    case 'english':
      return KidsVisualTheme.pathBlue;
    case 'chichewa':
      return KidsVisualTheme.trailGreen;
    case 'mathematics':
      return KidsVisualTheme.sunGold;
    case 'science':
      return const Color(0xFF8E44AD);
    case 'social studies':
      return DesignTokens.error;
    default:
      return DesignTokens.primary;
  }
}

IconData kidsSubjectIcon(String name) {
  switch (name.toLowerCase()) {
    case 'english':
      return Icons.abc_rounded;
    case 'chichewa':
      return Icons.translate_rounded;
    case 'mathematics':
      return Icons.calculate_rounded;
    case 'science':
      return Icons.science_rounded;
    case 'social studies':
      return Icons.public_rounded;
    default:
      return Icons.menu_book_rounded;
  }
}

String kidsMascotMessage(
    Map<String, dynamic>? dailySummary, KidAuthState auth) {
  final act = (dailySummary?['activitiesToday'] as num?)?.toInt() ?? 0;
  final goal = (dailySummary?['dailyGoal'] as num?)?.toInt() ?? 3;
  if (act >= goal) {
    return 'Today\u2019s goal is complete. You can still play lessons\u2014or rest. Both are great!';
  }
  final left = goal - act;
  final unit = left == 1 ? 'step' : 'steps';
  final track =
      auth.educationTrack == 'ecd' ? 'Little learner' : 'Super learner';
  return '$track, only $left small $unit left to fill today\u2019s ring.';
}
