import 'package:flutter/material.dart';

IconData achIcon(String? icon) {
  switch (icon) {
    case 'streak':
      return Icons.local_fire_department_rounded;
    case 'posts':
      return Icons.article_rounded;
    case 'comments':
      return Icons.chat_rounded;
    case 'karma':
      return Icons.trending_up_rounded;
    case 'votes':
      return Icons.arrow_upward_rounded;
    case 'awards':
      return Icons.auto_awesome_rounded;
    default:
      return Icons.emoji_events_rounded;
  }
}
