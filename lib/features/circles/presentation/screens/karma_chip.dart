import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class KarmaChip extends StatelessWidget {
  final String label;
  final int value;
  const KarmaChip({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: DesignTokens.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label: $value',
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: DesignTokens.primary)),
    );
  }
}
