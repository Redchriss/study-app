import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class FlairBar extends StatelessWidget {
  final List<Map<String, dynamic>> flairs;
  final String? flairId;
  final bool dark;
  final ValueChanged<String?> onFlairChanged;

  const FlairBar({
    super.key,
    required this.flairs,
    required this.flairId,
    required this.dark,
    required this.onFlairChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: flairs.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (_, i) {
          final selected =
              i == 0 ? flairId == null : flairId == flairs[i - 1]['id'];
          final label =
              i == 0 ? 'All' : flairs[i - 1]['text']?.toString() ?? '';
          final color = i == 0
              ? null
              : _parseColor(
                  flairs[i - 1]['backgroundColor']?.toString() ?? '#0079D3');
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: FilterChip(
              label: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? (color != null ? _textColorForBg(color) : Colors.white)
                      : DesignTokens.textSecondary,
                ),
              ),
              selected: selected,
              selectedColor: color ?? DesignTokens.primary,
              checkmarkColor: Colors.white,
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => onFlairChanged(
                  i == 0 ? null : flairs[i - 1]['id']?.toString()),
            ),
          );
        },
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final h = hex.replaceFirst('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return DesignTokens.primary;
    }
  }

  Color _textColorForBg(Color bg) {
    return bg.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}
