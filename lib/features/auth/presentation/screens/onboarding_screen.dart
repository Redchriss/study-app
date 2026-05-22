import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/app_preferences_service.dart';
import 'onboarding_data.dart';
import 'onboarding_last_page_actions.dart';
import 'onboarding_next_button.dart';
import 'onboarding_page.dart';
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
    OnboardingData(
      title: 'Your AI Study\nPartner',
      subtitle:
          'Get instant help with any subject.\nPersonal tutor. Available 24/7.',
      gradient: [Color(0xFF1B6CA8), Color(0xFF0E3D6E)],
      accentColor: Color(0xFF4FC3F7),
      icon: Icons.auto_awesome_rounded,
      stat: '24/7',
      statLabel: 'instant AI tutoring',
    ),
    OnboardingData(
      title: 'Built for\nMalawi',
      subtitle:
          'From PSLCE to MSCE, plus public & private\nuniversities and all TTCs.',
      gradient: [Color(0xFF1F6A52), Color(0xFF0D3B2E)],
      accentColor: Color(0xFF69F0AE),
      icon: Icons.flag_rounded,
      stat: '100%',
      statLabel: 'aligned to your syllabus',
    ),
    OnboardingData(
      title: 'Scan. Solve.\nLearn.',
      subtitle:
          'Point your camera at any past paper.\nGet step-by-step AI solutions instantly.',
      gradient: [Color(0xFF6A1B9A), Color(0xFF380B5A)],
      accentColor: Color(0xFFCE93D8),
      icon: Icons.document_scanner_rounded,
      stat: '∞',
      statLabel: 'papers you can solve',
    ),
    OnboardingData(
      title: 'Kids Mode\nIncluded',
      subtitle:
          'A safe, gamified learning space.\nAI generates storybook lessons for children.',
      gradient: [Color(0xFFD84315), Color(0xFF8B0000)],
      accentColor: Color(0xFFFFAB91),
      icon: Icons.child_care_rounded,
      stat: 'Safe',
      statLabel: 'PIN-protected environment',
    ),
    OnboardingData(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo
                      const Text(
                        'Yaza',
                        style: TextStyle(
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
                            foregroundColor:
                                Colors.white.withValues(alpha: 0.7),
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
                    itemBuilder: (_, i) => OnboardingPage(data: _pages[i]),
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
                      ? OnboardingLastPageActions(
                          preferredLevel: _preferredLevel,
                          preferredGoal: _preferredGoal,
                          onLevelSelected: (l) =>
                              setState(() => _preferredLevel = l),
                          onGoalSelected: (g) =>
                              setState(() => _preferredGoal = g),
                          onGetStarted: () async {
                            await _preferences
                                .setPreferredLevel(_preferredLevel);
                            await _preferences.setPreferredGoal(_preferredGoal);
                            if (context.mounted) context.go('/register');
                          },
                          onLogin: () => context.go('/login'),
                        )
                      : OnboardingNextButton(
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
