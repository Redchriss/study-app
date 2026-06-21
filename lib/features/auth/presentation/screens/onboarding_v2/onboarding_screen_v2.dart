import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/widgets/elite/soft_mesh_background.dart';
import '../onboarding_data.dart';

class OnboardingScreenV2 extends StatefulWidget {
  const OnboardingScreenV2({super.key});

  @override
  State<OnboardingScreenV2> createState() => _OnboardingScreenV2State();
}

class _OnboardingScreenV2State extends State<OnboardingScreenV2> {
  final _controller = PageController();
  int _page = 0;

  void _next() {
    if (_page < OnboardingData.pages.length - 1) {
      _controller.nextPage(
        duration: 800.ms,
        curve: Curves.elasticOut,
      );
    } else {
      context.go('/register');
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = OnboardingData.pages[_page];
    final isLast = _page == OnboardingData.pages.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          // The 'Elite' mesh background
          SoftMeshBackground(
            baseColor: data.gradient.first,
            accentColor: data.accentColor,
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(isLast),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemCount: OnboardingData.pages.length,
                    itemBuilder: (context, i) => _buildPage(OnboardingData.pages[i], i),
                  ),
                ),
                _buildFooter(isLast),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isLast) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Yaza',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontFamily: 'CalSans', // Custom elite font
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
          if (!isLast)
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Skip', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildPage(pageData, int index) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(pageData.icon, size: 80, color: Colors.white),
          ).animate(key: ValueKey(index))
           .scale(duration: 600.ms, curve: Curves.elasticOut)
           .fadeIn(),
          const SizedBox(height: 48),
          Text(
            pageData.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ).animate(key: ValueKey(index)).fadeIn(delay: 200.ms).slideY(begin: 0.2),
          const SizedBox(height: 24),
          Text(
            pageData.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ).animate(key: ValueKey(index)).fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isLast) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              OnboardingData.pages.length,
              (i) => AnimatedContainer(
                duration: 400.ms,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _page == i ? 32 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _page == i ? Colors.white : Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 72,
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 0,
              ),
              child: Text(
                isLast ? 'Get Started' : 'Continue',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ).animate(key: ValueKey(isLast))
             .shimmer(delay: 2.seconds, duration: 2.seconds),
          ),
        ],
      ),
    );
  }
}
