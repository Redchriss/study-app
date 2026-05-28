import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import 'material_reader_models.dart';

class TextReaderPageWidget extends StatelessWidget {
  const TextReaderPageWidget({
    super.key,
    required this.material,
    required this.currentPage,
    required this.selectedParagraphIndex,
    required this.paragraphs,
    required this.onParagraphTap,
  });

  final ReaderMaterialData material;
  final int currentPage;
  final int? selectedParagraphIndex;
  final List<String> paragraphs;
  final ValueChanged<int> onParagraphTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
            boxShadow: DesignTokens.shadowLg(false),
            border: Border.all(color: const Color(0xFFD6C7AB)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (material.subjectName.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: DesignTokens.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(material.subjectName,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: DesignTokens.primary)),
                      ),
                    const Spacer(),
                    Text('${currentPage + 1}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: DesignTokens.textTertiary)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: dark
                        ? DesignTokens.darkSurfaceVariant
                        : const Color(0xFFF8F2E3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Tap a paragraph to highlight that exact section for notes, quiz, or AI help.',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: dark
                            ? DesignTokens.darkTextSecondary
                            : DesignTokens.textSecondary),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    itemCount: paragraphs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, paragraphIndex) {
                      final selected = selectedParagraphIndex == paragraphIndex;
                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => onParagraphTap(paragraphIndex),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: selected
                                ? (dark
                                    ? DesignTokens.primary
                                        .withValues(alpha: 0.18)
                                    : const Color(0xFFF3E6BE))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected
                                  ? (dark
                                      ? DesignTokens.primaryLight
                                          .withValues(alpha: 0.5)
                                      : const Color(0xFFC28A2C))
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(paragraphs[paragraphIndex],
                              style: const TextStyle(
                                  fontSize: 18,
                                  height: 1.75,
                                  color: DesignTokens.textPrimary)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  currentPage == material.textPages.length - 1
                      ? 'End of notes'
                      : 'Swipe for next page',
                  style: const TextStyle(
                      fontSize: 12,
                      color: DesignTokens.textSecondary,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
