import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

Color materialSubjectColor(String name) {
  switch (name.toLowerCase()) {
    case 'english':
    case 'chichewa':
      return DesignTokens.primary;
    case 'mathematics':
      return DesignTokens.warning;
    case 'science':
    case 'biology':
    case 'chemistry':
      return DesignTokens.success;
    case 'social studies':
    case 'history':
      return DesignTokens.error;
    default:
      return DesignTokens.accent;
  }
}

Color materialTypeColor(String type) {
  switch (type.toLowerCase()) {
    case 'pdf':
      return const Color(0xFFE74C3C);
    case 'video':
      return const Color(0xFF9B59B6);
    case 'text':
      return DesignTokens.primary;
    case 'image':
      return DesignTokens.success;
    default:
      return DesignTokens.accent;
  }
}

IconData materialTypeIcon(String type) {
  switch (type.toLowerCase()) {
    case 'pdf':
      return Icons.picture_as_pdf_rounded;
    case 'video':
      return Icons.play_circle_rounded;
    case 'text':
      return Icons.article_rounded;
    case 'image':
      return Icons.image_rounded;
    default:
      return Icons.description_rounded;
  }
}

String materialLevelLabel(String level) {
  switch (level.toLowerCase()) {
    case 'primary':
      return 'Primary';
    case 'tertiary':
      return 'Uni';
    case 'secondary':
      return 'Secondary';
    default:
      return '';
  }
}

String materialFormatViews(int views) {
  if (views >= 1000) return '${(views / 1000).toStringAsFixed(1)}k';
  return '$views';
}
