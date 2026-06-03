import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class QuizResultsScoreGauge extends StatelessWidget {
  final double pct;
  final int correct;
  final int total;
  final String score;
  final bool dark;
  const QuizResultsScoreGauge(
      {required this.pct,
      required this.correct,
      required this.total,
      required this.score,
      required this.dark});

  Color get _gradeColor {
    if (pct >= 0.9) return DesignTokens.success;
    if (pct >= 0.7) return DesignTokens.primary;
    if (pct >= 0.5) return DesignTokens.warning;
    return DesignTokens.error;
  }

  String get _gradeLabel {
    if (pct >= 0.9) return 'Excellent';
    if (pct >= 0.7) return 'Good';
    if (pct >= 0.5) return 'Keep trying';
    return 'Needs work';
  }

  String get _gradeEmoji {
    if (pct >= 0.9) return '\u{1F3C6}';
    if (pct >= 0.7) return '\u{1F44D}';
    if (pct >= 0.5) return '\u{1F4AA}';
    return '\u{1F4DA}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _gradeColor.withValues(alpha: 0.1),
              _gradeColor.withValues(alpha: 0.02)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _gradeColor.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Text(_gradeEmoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(fit: StackFit.expand, children: [
              CircularProgressIndicator(
                value: pct,
                strokeWidth: 8,
                backgroundColor:
                    (dark ? DesignTokens.darkBorder : DesignTokens.border)
                        .withValues(alpha: 0.5),
                valueColor: AlwaysStoppedAnimation(_gradeColor),
              ),
              Center(
                child: Text(
                  '$score%',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _gradeColor),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Text(_gradeLabel,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _gradeColor)),
          const SizedBox(height: 4),
          Text('$correct of $total correct',
              style: TextStyle(
                  fontSize: 13,
                  color: dark
                      ? DesignTokens.darkTextSecondary
                      : DesignTokens.textSecondary)),
        ]),
      ),
    );
  }
}
