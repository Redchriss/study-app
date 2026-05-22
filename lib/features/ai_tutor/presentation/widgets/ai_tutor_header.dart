import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../widgets/ai_tutor_mode_bar.dart';
import '../widgets/ai_tutor_snapshot_cards.dart';

class AiTutorHeader extends StatelessWidget {
  final String studyMode;
  final List<(String, String, IconData)> modes;
  final String modeHint;
  final bool snapshotLoading;
  final List<Map<String, dynamic>> topicStates;
  final List<Map<String, dynamic>> memories;
  final Map<String, dynamic>? activePlan;
  final int reviewCount;
  final bool showInsights;
  final ValueChanged<String> onModeSelect;
  final VoidCallback onGeneratePlan;
  final VoidCallback onToggleInsights;

  const AiTutorHeader({
    super.key,
    required this.studyMode,
    required this.modes,
    required this.modeHint,
    required this.snapshotLoading,
    required this.topicStates,
    required this.memories,
    required this.activePlan,
    required this.reviewCount,
    required this.showInsights,
    required this.onModeSelect,
    required this.onGeneratePlan,
    required this.onToggleInsights,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Container(
      color:
          dark ? DesignTokens.darkSurfaceVariant : DesignTokens.surfaceVariant,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: Row(
              children: [
                Expanded(
                    child: AiTutorModeBar(
                        selectedMode: studyMode,
                        modes: modes,
                        onSelect: onModeSelect)),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onToggleInsights,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: showInsights
                          ? const Color(0xFF7C4DFF).withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: showInsights
                              ? const Color(0xFF7C4DFF)
                              : DesignTokens.textTertiary
                                  .withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.psychology_rounded,
                            size: 16,
                            color: showInsights
                                ? const Color(0xFF7C4DFF)
                                : DesignTokens.textSecondary),
                        if (reviewCount > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                                color: DesignTokens.warning,
                                borderRadius: BorderRadius.circular(999)),
                            child: Text('$reviewCount',
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
            child: Row(
              children: [
                Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                        color: Color(0xFF7C4DFF), shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(modeHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: DesignTokens.textSecondary,
                        fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: showInsights && !snapshotLoading
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: AiTutorSnapshotCards(
                      reviewCount: reviewCount,
                      topicStates: topicStates,
                      memories: memories,
                      planSummary: activePlan?['planSummary']?.toString(),
                      onGeneratePlan: onGeneratePlan,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
