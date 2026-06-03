import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class AiTutorSurfacePlaceholder extends StatefulWidget {
  @override
  State<AiTutorSurfacePlaceholder> createState() =>
      _AiTutorSurfacePlaceholderState();
}

class _AiTutorSurfacePlaceholderState extends State<AiTutorSurfacePlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 0.7).animate(_pulseCtrl),
      child: Container(
        height: 120,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? DesignTokens.darkSurfaceVariant
              : DesignTokens.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('Building interactive widget...',
                  style: TextStyle(
                      fontSize: 12, color: DesignTokens.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
