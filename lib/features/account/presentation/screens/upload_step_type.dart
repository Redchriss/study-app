import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/design_tokens.dart';

const kUploadTypes = [
  ('pdf', 'PDF Document', 'Upload a PDF booklet or handout',
      Icons.picture_as_pdf_rounded, Color(0xFFC8583D)),
  ('text', 'Notes & Text', 'Paste notes or attach a document',
      Icons.menu_book_rounded, Color(0xFF1F6A52)),
  ('image', 'Image / Diagram', 'Upload a photo or diagram',
      Icons.image_rounded, Color(0xFF7A4D9E)),
  ('video', 'Video Lesson', 'Link a YouTube video lesson',
      Icons.ondemand_video_rounded, Color(0xFF005B8F)),
];

class UploadStepType extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const UploadStepType({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What are you sharing?',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Choose the format that best describes your material.',
              style: TextStyle(
                  color: DesignTokens.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: kUploadTypes.map((t) {
              final (val, label, desc, icon, color) = t;
              final isSelected = selected == val;
              return GestureDetector(
                onTap: () {
                  HapticService.selection();
                  onChanged(val);
                },
                child: AnimatedContainer(
                  duration: DesignTokens.durFast,
                  width: 155,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(colors: [
                            color, color.withValues(alpha: 0.7)])
                        : null,
                    color: isSelected
                        ? null
                        : (dark ? DesignTokens.darkSurface : DesignTokens.surface),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (dark ? DesignTokens.darkBorder : DesignTokens.border),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : DesignTokens.shadowSm(dark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon,
                                color: isSelected ? Colors.white : color,
                                size: 22),
                          ),
                          const Spacer(),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 20),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(label,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isSelected
                                  ? Colors.white
                                  : null)),
                      const SizedBox(height: 2),
                      Text(desc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : DesignTokens.textSecondary)),
                    ],
                  ),
                ),
              );
            }).toList(),
          )
              .animate()
              .fadeIn(duration: 300.ms, curve: Curves.easeOut)
              .slideY(begin: 0.04),
        ],
      ),
    );
  }
}
