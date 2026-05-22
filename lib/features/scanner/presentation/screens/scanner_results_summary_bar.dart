import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/design_tokens.dart';

class ScannerResultsSummaryBar extends StatelessWidget {
  final List solutions;
  final bool dark;

  const ScannerResultsSummaryBar(
      {super.key, required this.solutions, required this.dark});

  @override
  Widget build(BuildContext context) {
    final total = solutions.length;
    final withAnswer = solutions.where((s) {
      final a = (s as Map<String, dynamic>)['answer'];
      return a != null && a != 'N/A' && (a as String).trim().isNotEmpty;
    }).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.primary.withValues(alpha: 0.12),
            DesignTokens.accent.withValues(alpha: 0.08)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: DesignTokens.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: DesignTokens.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'AI solved $withAnswer of $total question${total == 1 ? '' : 's'}',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: DesignTokens.primary),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: DesignTokens.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
            ),
            child: Text('${((withAnswer / total) * 100).round()}%',
                style: const TextStyle(
                  color: DesignTokens.success,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                )),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
