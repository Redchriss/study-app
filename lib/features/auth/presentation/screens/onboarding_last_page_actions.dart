import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class OnboardingLastPageActions extends StatelessWidget {
  final String? preferredLevel;
  final String preferredGoal;
  final ValueChanged<String> onLevelSelected;
  final ValueChanged<String> onGoalSelected;
  final VoidCallback onGetStarted;
  final VoidCallback onLogin;

  const OnboardingLastPageActions({
    super.key,
    required this.preferredLevel,
    required this.preferredGoal,
    required this.onLevelSelected,
    required this.onGoalSelected,
    required this.onGetStarted,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    const levels = [
      ('primary', 'Primary', Icons.child_care_rounded),
      ('secondary', 'Secondary', Icons.school_rounded),
      ('tertiary', 'University', Icons.account_balance_rounded),
    ];
    const goals = [
      ('read', 'Materials', Icons.menu_book_rounded),
      ('quiz', 'Quizzes', Icons.quiz_rounded),
      ('ai', 'AI Tutor', Icons.auto_awesome_rounded),
    ];
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('What level are you?',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              const SizedBox(height: 12),
              Row(
                children: levels.map((item) {
                  final selected = preferredLevel == item.$1;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onLevelSelected(item.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: selected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          children: [
                            Icon(item.$3,
                                size: 20,
                                color: selected
                                    ? DesignTokens.primary
                                    : Colors.white.withValues(alpha: 0.7)),
                            const SizedBox(height: 4),
                            Text(item.$2,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? DesignTokens.primary
                                        : Colors.white.withValues(alpha: 0.7))),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('What do you want first?',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              const SizedBox(height: 12),
              Row(
                children: goals.map((item) {
                  final selected = preferredGoal == item.$1;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onGoalSelected(item.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: selected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          children: [
                            Icon(item.$3,
                                size: 20,
                                color: selected
                                    ? DesignTokens.primary
                                    : Colors.white.withValues(alpha: 0.7)),
                            const SizedBox(height: 4),
                            Text(item.$2,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? DesignTokens.primary
                                        : Colors.white.withValues(alpha: 0.7))),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: onGetStarted,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: DesignTokens.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text("Get Started — It's Free",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onLogin,
          style: TextButton.styleFrom(
              foregroundColor: Colors.white.withValues(alpha: 0.8)),
          child: const Text('Already have an account? Log in',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
