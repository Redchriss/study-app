import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/services/study_progress_store.dart';

// ── Type Filter Bar ───────────────────────────────────────────────────────────

class MaterialTypeFilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const MaterialTypeFilterBar({super.key, required this.selected, required this.onSelect});

  static const _types = [
    ('all', 'All', Icons.grid_view_rounded),
    ('pdf', 'PDF', Icons.picture_as_pdf_rounded),
    ('video', 'Video', Icons.play_circle_rounded),
    ('text', 'Notes', Icons.article_rounded),
    ('image', 'Images', Icons.image_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final type = _types[i];
          final isSelected = selected == type.$1;
          return FilterChip(
            selected: isSelected,
            avatar: Icon(type.$3, size: 16),
            label: Text(type.$2),
            onSelected: (_) => onSelect(type.$1),
            showCheckmark: false,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }
}

// ── Continue Card ─────────────────────────────────────────────────────────────

class MaterialContinueCard extends StatelessWidget {
  final StudyMaterialProgress progress;
  final bool dark;
  final VoidCallback onTap;
  const MaterialContinueCard({super.key, required this.progress, required this.dark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: AnimatedPress(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1B6CA8), Color(0xFF0D2E4A)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: const Color(0xFF1B6CA8).withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CONTINUE READING', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    const SizedBox(height: 3),
                    Text(progress.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(
                      progress.subjectName.isEmpty ? progress.progressLabel : '${progress.subjectName} · ${progress.progressLabel}',
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 40, height: 40,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(value: progress.completionRatio, strokeWidth: 3, backgroundColor: Colors.white.withValues(alpha: 0.2), valueColor: const AlwaysStoppedAnimation<Color>(Colors.white)),
                    Center(child: Text('${(progress.completionRatio * 100).round()}%', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white60, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Banner ────────────────────────────────────────────────────────────────────

class MaterialInfoBanner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  final bool dark;
  const MaterialInfoBanner({super.key, required this.color, required this.icon, required this.text, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dark ? DesignTokens.darkTextPrimary : DesignTokens.textPrimary))),
        ],
      ),
    );
  }
}
