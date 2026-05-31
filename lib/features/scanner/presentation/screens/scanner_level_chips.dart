import 'package:flutter/material.dart';
import 'scanner_shared_widgets.dart';

class ScannerLevelChips extends StatelessWidget {
  final String? educationLevel;
  final ValueChanged<String> onLevelChanged;

  const ScannerLevelChips({
    super.key,
    required this.educationLevel,
    required this.onLevelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        LevelChip(
            label: 'Primary',
            icon: Icons.child_care_rounded,
            selected: educationLevel == 'primary',
            onTap: () => onLevelChanged('primary')),
        const SizedBox(width: 8),
        LevelChip(
            label: 'Secondary',
            icon: Icons.menu_book_rounded,
            selected: educationLevel == 'secondary',
            onTap: () => onLevelChanged('secondary')),
        const SizedBox(width: 8),
        LevelChip(
            label: 'Tertiary',
            icon: Icons.account_balance_rounded,
            selected: educationLevel == 'tertiary',
            onTap: () => onLevelChanged('tertiary')),
      ],
    );
  }
}
