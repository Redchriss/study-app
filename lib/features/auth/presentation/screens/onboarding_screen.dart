import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/app_preferences_service.dart';
import '../../../../core/theme/design_tokens.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _preferences = AppPreferencesService();
  final _controller = PageController();
  int _page = 0;
  String? _preferredLevel;
  String _preferredGoal = 'read';

  late final AnimationController _bgAnimCtrl;
  late final Animation<double> _bgAnim;

  static const _pages = [
    _OnboardingData(
      title: 'Your AI Study\nPartner',
      subtitle: 'Get instant help with any subject.\nPersonal tutor. Available 24/7.',
      gradient: [Color(0xFF1B6CA8), Color(0xFF0E3D6E)],
      accentColor: Color(0xFF4FC3F7),
      icon: Icons.auto_awesome_rounded,
      stat: '24/7',
      statLabel: 'instant AI tutoring',
    ),
    _OnboardingData(
      title: 'Built for\nMalawi',
      subtitle: 'From PSLCE to MSCE, plus UNIMA,\nMUBAS, MUST, and LUANAR.',
      gradient: [Color(0xFF1F6A52), Color(0xFF0D3B2E)],
      accentColor: Color(0xFF69F0AE),
      icon: Icons.flag_rounded,
      stat: '100%',
      statLabel: 'aligned to your syllabus',
    ),
    _OnboardingData(
      title: 'Scan. Solve.\nLearn.',
      subtitle: 'Point your camera at any past paper.\nGet step-by-step AI solutions instantly.',
      gradient: [Color(0xFF6A1B9A), Color(0xFF380B5A)],
      accentColor: Color(0xFFCE93D8),
      icon: Icons.document_scanner_rounded,
      stat: '∞',
      statLabel: 'papers you can solve',
    ),
    _OnboardingData(
      title: 'Kids Mode\nIncluded',
      subtitle: 'A safe, gamified learning space.\nAI generates storybook lessons for children.',
      gradient: [Color(0xFFD84315), Color(0xFF8B0000)],
      accentColor: Color(0xFFFFAB91),
      icon: Icons.child_care_rounded,
      stat: 'Safe',
      statLabel: 'PIN-protected environment',
    ),
    _OnboardingData(
      title: 'Get Started\nfor Free',
      subtitle: 'No credit card needed.\n3 free AI credits on signup.',
      gradient: [Color(0xFFE65100), Color(0xFF3E2723)],
      accentColor: Color(0xFFFFCC80),
      icon: Icons.bolt_rounded,
      stat: '3',
      statLabel: 'free AI credits to try',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bgAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _bgAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bgAnimCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bgAnimCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _pages[_page];
    final isLast = _page == _pages.length - 1;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _bgAnim,
            builder: (_, __) => AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(
                    math.cos(_bgAnim.value * math.pi) * 0.3,
                    -1,
                  ),
                  end: Alignment(
                    math.sin(_bgAnim.value * math.pi) * 0.3,
                    1,
                  ),
                  colors: data.gradient,
                ),
              ),
            ),
          ),
          // Decorative circles
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            top: -size.width * 0.3,
            right: -size.width * 0.2,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: data.accentColor.withValues(alpha: 0.08),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            bottom: -size.width * 0.4,
            left: -size.width * 0.2,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: size.width,
              height: size.width,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: data.accentColor.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Content
          SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Logo
                        Text(
                          'Yaza',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (!isLast)
                          TextButton(
                            onPressed: () => context.go('/login'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white.withValues(alpha: 0.7),
                            ),
                            child: const Text('Skip'),
                          ),
                      ],
                    ),
                  ),
                  // PageView
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemCount: _pages.length,
                      itemBuilder: (_, i) => _OnboardingPage(data: _pages[i]),
                    ),
                  ),
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _page == i ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _page == i
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Bottom actions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: isLast
                        ? _LastPageActions(
                            preferredLevel: _preferredLevel,
                            preferredGoal: _preferredGoal,
                            onLevelSelected: (l) =>
                                setState(() => _preferredLevel = l),
                            onGoalSelected: (g) =>
                                setState(() => _preferredGoal = g),
                            onGetStarted: () async {
                              await _preferences
                                  .setPreferredLevel(_preferredLevel);
                              await _preferences
                                  .setPreferredGoal(_preferredGoal);
                              if (context.mounted) context.go('/register');
                            },
                            onLogin: () => context.go('/login'),
                          )
                        : _NextButton(
                            accentColor: data.accentColor,
                            onPressed: _next,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }
}

class _OnboardingData {
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final Color accentColor;
  final IconData icon;
  final String stat;
  final String statLabel;

  const _OnboardingData({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.accentColor,
    required this.icon,
    required this.stat,
    required this.statLabel,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(
                color: data.accentColor.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Icon(
              data.icon,
              size: 56,
              color: data.accentColor,
            ),
          )
              .animate()
              .scale(
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
              )
              .fadeIn(),
          const SizedBox(height: 40),
          Text(
            data.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -1.5,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .slideY(
                begin: 0.3,
                duration: const Duration(milliseconds: 500),
                delay: const Duration(milliseconds: 100),
                curve: Curves.easeOutCubic,
              )
              .fadeIn(delay: const Duration(milliseconds: 100)),
          const SizedBox(height: 16),
          Text(
            data.subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 17,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .slideY(
                begin: 0.3,
                duration: const Duration(milliseconds: 500),
                delay: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
              )
              .fadeIn(delay: const Duration(milliseconds: 200)),
          const SizedBox(height: 40),
          // Stat pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: data.accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: data.accentColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.stat,
                  style: TextStyle(
                    color: data.accentColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  data.statLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(
                delay: const Duration(milliseconds: 400),
                duration: const Duration(milliseconds: 400),
              ),
        ],
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  final Color accentColor;
  final VoidCallback onPressed;
  const _NextButton({required this.accentColor, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: DesignTokens.textPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Next',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}

class _LastPageActions extends StatelessWidget {
  final String? preferredLevel;
  final String preferredGoal;
  final ValueChanged<String> onLevelSelected;
  final ValueChanged<String> onGoalSelected;
  final VoidCallback onGetStarted;
  final VoidCallback onLogin;

  const _LastPageActions({
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
              const Text(
                'What level are you?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
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
                                : Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              item.$3,
                              size: 20,
                              color: selected
                                  ? DesignTokens.primary
                                  : Colors.white.withValues(alpha: 0.7),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.$2,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? DesignTokens.primary
                                    : Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'What do you want first?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
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
                                : Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              item.$3,
                              size: 20,
                              color: selected
                                  ? DesignTokens.primary
                                  : Colors.white.withValues(alpha: 0.7),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.$2,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? DesignTokens.primary
                                    : Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
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
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Get Started — It\'s Free',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onLogin,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white.withValues(alpha: 0.8),
          ),
          child: const Text(
            'Already have an account? Log in',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
