import 'package:flutter/material.dart';

class OnboardingData {
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final Color accentColor;
  final IconData icon;
  final String stat;
  final String statLabel;

  const OnboardingData({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.accentColor,
    required this.icon,
    required this.stat,
    required this.statLabel,
  });
}
