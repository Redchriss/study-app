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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
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
                  child: const Text("Get Started — Free",
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: onLogin,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side:
                        BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Log In',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '3 free AI credits on sign up · No card needed',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
