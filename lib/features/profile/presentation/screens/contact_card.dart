import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/design_tokens.dart';

class ContactCard extends StatelessWidget {
  final bool dark;
  const ContactCard({super.key, required this.dark});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B6CA8), Color(0xFF2EC4B6)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Get in Touch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 6),
          const Text('We respond to every message within 24 hours.', style: TextStyle(fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse('mailto:support@yaza.app');
              if (await canLaunchUrl(uri)) await launchUrl(uri);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mail_rounded, color: DesignTokens.primary, size: 18),
                  SizedBox(width: 8),
                  Text('support@yaza.app', style: TextStyle(fontWeight: FontWeight.w800, color: DesignTokens.primary, fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }
}
