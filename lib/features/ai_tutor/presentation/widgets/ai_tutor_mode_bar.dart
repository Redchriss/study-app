import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';

class AiTutorModeBar extends StatelessWidget {
  const AiTutorModeBar({
    super.key,
    required this.selectedMode,
    required this.modes,
    required this.onSelect,
  });

  final String selectedMode;
  final List<(String, String, IconData)> modes;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: modes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = modes[index];
          final selected = item.$1 == selectedMode;
          return Material(
            color:
                selected ? DesignTokens.primary : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onSelect(item.$1),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.$3,
                        size: 18,
                        color: selected
                            ? Colors.white
                            : DesignTokens.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      item.$2,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color:
                            selected ? Colors.white : DesignTokens.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
