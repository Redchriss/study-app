import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';

class MaterialsEmptyState extends StatelessWidget {
  final bool dark;

  const MaterialsEmptyState({super.key, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: DesignTokens.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 18,
                  left: 18,
                  child: Container(
                    width: 28,
                    height: 36,
                    decoration: BoxDecoration(
                      color: DesignTokens.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 18,
                  right: 18,
                  child: Container(
                    width: 28,
                    height: 36,
                    decoration: BoxDecoration(
                      color: DesignTokens.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const Icon(Icons.menu_book_rounded,
                    size: 40, color: DesignTokens.primary),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No materials yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: dark
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to upload study materials\nfor your classmates.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: dark
                    ? DesignTokens.darkTextSecondary
                    : DesignTokens.textSecondary),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push('/upload-material'),
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Upload Material'),
          ),
        ],
      ),
    );
  }
}
