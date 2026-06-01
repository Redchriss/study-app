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

  static const pages = [
    OnboardingData(
      title: 'Your AI Study\nPartner',
      subtitle: 'Get instant help with any subject.\nPersonal tutor. Available 24/7.',
      gradient: [Color(0xFF1B6CA8), Color(0xFF0E3D6E)],
      accentColor: Color(0xFF4FC3F7),
      icon: Icons.auto_awesome_rounded,
      stat: '24/7',
      statLabel: 'instant AI tutoring',
    ),
    OnboardingData(
      title: 'Built for\nMalawi',
      subtitle: 'From PSLCE to MSCE, plus public & private\nuniversities and all TTCs.',
      gradient: [Color(0xFF1F6A52), Color(0xFF0D3B2E)],
      accentColor: Color(0xFF69F0AE),
      icon: Icons.flag_rounded,
      stat: '100%',
      statLabel: 'aligned to your syllabus',
    ),
    OnboardingData(
      title: 'Scan. Solve.\nLearn.',
      subtitle: 'Point your camera at any past paper.\nGet step-by-step AI solutions instantly.',
      gradient: [Color(0xFF6A1B9A), Color(0xFF380B5A)],
      accentColor: Color(0xFFCE93D8),
      icon: Icons.document_scanner_rounded,
      stat: '∞',
      statLabel: 'papers you can solve',
    ),
    OnboardingData(
      title: 'Get Started\nfor Free',
      subtitle: 'No credit card needed.\n3 free AI credits on signup.',
      gradient: [Color(0xFFE65100), Color(0xFF3E2723)],
      accentColor: Color(0xFFFFCC80),
      icon: Icons.bolt_rounded,
      stat: '3',
      statLabel: 'free AI credits to try',
    ),
  ];
}
