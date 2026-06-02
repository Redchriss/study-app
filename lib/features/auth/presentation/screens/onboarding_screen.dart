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
  final _controller = PageController();
  int _page = 0;
  late final AnimationController _bgAnimCtrl;
  late final Animation<double> _bgAnim;

  @override
  void initState() {
    super.initState();
    _bgAnimCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat(reverse: true);
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
    if (_page < OnboardingData.pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = OnboardingData.pages[_page];
    final isLast = _page == OnboardingData.pages.length - 1;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgAnim,
            builder: (_, __) => AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(math.cos(_bgAnim.value * math.pi) * 0.3, -1),
                  end: Alignment(math.sin(_bgAnim.value * math.pi) * 0.3, 1),
                  colors: data.gradient,
                ),
              ),
            ),
          ),
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
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Yaza',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5),
                      ),
                      if (!isLast)
                        TextButton(
                          onPressed: () => context.go('/login'),
                          style: TextButton.styleFrom(
                              foregroundColor:
                                  Colors.white.withValues(alpha: 0.7)),
                          child: const Text('Skip'),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemCount: OnboardingData.pages.length,
                    itemBuilder: (_, i) =>
                        OnboardingPage(data: OnboardingData.pages[i]),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    OnboardingData.pages.length,
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
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: isLast
                      ? OnboardingLastPageActions(
                          preferredLevel: null,
                          preferredGoal: 'read',
                          onLevelSelected: (_) {},
                          onGoalSelected: (_) {},
                          onGetStarted: () => context.go('/register'),
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
