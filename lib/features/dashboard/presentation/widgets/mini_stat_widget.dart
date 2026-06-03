import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class MiniStat extends StatelessWidget {
  final String value;
  final String label;
  const MiniStat({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900, color: DesignTokens.primary)),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: DesignTokens.textTertiary,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
