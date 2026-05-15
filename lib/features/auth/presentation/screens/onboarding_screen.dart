import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/app_preferences_service.dart';
import '../../../../core/theme/design_tokens.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _preferences = AppPreferencesService();
  final _controller = PageController();
  int _page = 0;
  String? _preferredLevel;
  String _preferredGoal = 'read';

  final _pages = const [
    _OnboardingPage(
      icon: Icons.psychology,
      title: 'Your AI Study Partner',
      subtitle: 'Get instant help with any subject. Your personal tutor, available 24/7.',
    ),
    _OnboardingPage(
      icon: Icons.flag,
      title: 'Built for Malawi',
      subtitle: 'PSLCE, JCE, MSCE — we know your syllabus inside out.',
    ),
    _OnboardingPage(
      icon: Icons.bolt,
      title: 'Start for Free',
      subtitle: 'Get 3 free AI credits on signup. No credit card needed.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: _pages,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _page == i ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _page == i ? DesignTokens.primary : DesignTokens.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  if (_page < _pages.length - 1)
                    ElevatedButton(
                      onPressed: () => _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                      child: const Text('Next'),
                    )
                  else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: DesignTokens.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Who are you?', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: const [
                              ('primary', 'Primary'),
                              ('secondary', 'Secondary'),
                              ('tertiary', 'College / University'),
                            ].map((item) {
                              return ChoiceChip(
                                label: Text(item.$2),
                                selected: _preferredLevel == item.$1,
                                onSelected: (_) => setState(() => _preferredLevel = item.$1),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                          const Text('What do you want first?', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: const [
                              ('read', 'Open materials'),
                              ('quiz', 'Practice quizzes'),
                              ('ai', 'Use AI tutor'),
                            ].map((item) {
                              return ChoiceChip(
                                label: Text(item.$2),
                                selected: _preferredGoal == item.$1,
                                onSelected: (_) => setState(() => _preferredGoal = item.$1),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final router = GoRouter.of(context);
                        await _preferences.setPreferredLevel(_preferredLevel);
                        await _preferences.setPreferredGoal(_preferredGoal);
                        router.go('/register');
                      },
                      child: const Text('Get Started'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Already have an account? Log in'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _OnboardingPage({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: DesignTokens.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 60, color: DesignTokens.primary),
          ),
          const SizedBox(height: 32),
          Text(title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(subtitle, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: DesignTokens.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
