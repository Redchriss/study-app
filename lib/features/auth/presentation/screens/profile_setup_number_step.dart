import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import 'profile_step_card.dart';

class ProfileNumberStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final String label;
  final int count;
  final Color color;
  final ValueChanged<int> onSelect;

  const ProfileNumberStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.label,
    required this.count,
    required this.color,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: DesignTokens.textSecondary),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: List.generate(
                count,
                (i) => ProfileNumberCard(
                  number: i + 1,
                  label: label,
                  subtitle: label == 'Form' ? (i < 2 ? 'JCE' : 'MSCE') : null,
                  color: color,
                  dark: dark,
                  onTap: () => onSelect(i + 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
