import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: () => context.push('/search'),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: dark
                ? DesignTokens.darkSurfaceVariant
                : DesignTokens.surfaceVariant,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),
              const Icon(Icons.search_rounded,
                  size: 18, color: DesignTokens.textTertiary),
              const SizedBox(width: 8),
              Text(
                'Search posts, communities...',
                style: TextStyle(
                  fontSize: 13,
                  color: dark
                      ? DesignTokens.darkTextTertiary
                      : DesignTokens.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
