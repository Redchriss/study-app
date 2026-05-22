import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'onboarding_data.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;
  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(color: data.accentColor.withValues(alpha: 0.5), width: 2),
            ),
            child: Icon(data.icon, size: 56, color: data.accentColor),
          ).animate().scale(duration: const Duration(milliseconds: 600), curve: Curves.elasticOut).fadeIn(),
          const SizedBox(height: 40),
          Text(
            data.title,
            style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -1.5),
            textAlign: TextAlign.center,
          ).animate().slideY(begin: 0.3, duration: const Duration(milliseconds: 500), delay: const Duration(milliseconds: 100), curve: Curves.easeOutCubic).fadeIn(delay: const Duration(milliseconds: 100)),
          const SizedBox(height: 16),
          Text(
            data.subtitle,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 17, height: 1.6),
            textAlign: TextAlign.center,
          ).animate().slideY(begin: 0.3, duration: const Duration(milliseconds: 500), delay: const Duration(milliseconds: 200), curve: Curves.easeOutCubic).fadeIn(delay: const Duration(milliseconds: 200)),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: data.accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: data.accentColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(data.stat, style: TextStyle(color: data.accentColor, fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(width: 8),
                Text(data.statLabel, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ).animate().fadeIn(delay: const Duration(milliseconds: 400), duration: const Duration(milliseconds: 400)),
        ],
      ),
    );
  }
}
