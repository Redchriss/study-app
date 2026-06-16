import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/services/biometric_service.dart';
import '../providers/auth_provider.dart';

/// Cinema-grade splash screen with animated gradient, floating orbs,
/// and a polished brand reveal.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  Timer? _timeoutTimer;
  late final AnimationController _pulseCtrl;
  late final AnimationController _gradientCtrl;
  late final AnimationController _orbitCtrl;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: 2.seconds,
    )..repeat(reverse: true);

    _gradientCtrl = AnimationController(
      vsync: this,
      duration: 8.seconds,
    )..repeat();

    _orbitCtrl = AnimationController(
      vsync: this,
      duration: 12.seconds,
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) => _listen());
    // Hard timeout — go to login if stuck for 20s
    _timeoutTimer = Timer(const Duration(seconds: 20), () {
      if (mounted) context.go('/login');
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _pulseCtrl.dispose();
    _gradientCtrl.dispose();
    _orbitCtrl.dispose();
    super.dispose();
  }

  void _listen() {
    ref.listen(authProvider, (prev, next) {
      if (!next.isLoading && !next.biometricRequired) {
        _timeoutTimer?.cancel();
      }
      if (next.biometricRequired) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _doBiometric());
      }
    });
  }

  Future<void> _doBiometric() async {
    final ok = await BiometricService().authenticate();
    if (!mounted) return;
    if (ok) {
      await ref.read(authProvider.notifier).completeBiometric();
    } else {
      await ref.read(authProvider.notifier).failBiometric();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _gradientCtrl,
      builder: (context, _) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    const Color(0xFF1B6CA8),
                    const Color(0xFF0D2E4A),
                    _gradientCtrl.value,
                  )!,
                  Color.lerp(
                    const Color(0xFF0D2E4A),
                    const Color(0xFF1A4A6E),
                    _gradientCtrl.value,
                  )!,
                  Color.lerp(
                    const Color(0xFF0A1E33),
                    const Color(0xFF0D2E4A),
                    _gradientCtrl.value,
                  )!,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Floating orbs
                ...List.generate(3, (i) => _Orb(i, _orbitCtrl)),
                // Main content
                SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated book icon
                        _AnimatedBookIcon(pulseCtrl: _pulseCtrl),
                        const SizedBox(height: 32),
                        // Brand name
                        const Text(
                          'Yaza',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.5,
                            height: 1,
                          ),
                        ).animate().fadeIn(
                              duration: 800.ms,
                              curve: Curves.easeOut,
                            ).slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        Text(
                          'Your AI study companion',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ).animate(delay: 300.ms).fadeIn(
                              duration: 600.ms,
                            ),
                        const SizedBox(height: 64),
                        // Premium loading indicator
                        _PremiumLoader(pulseCtrl: _pulseCtrl),
                      ],
                    ),
                  ),
                ),
                // Bottom branding
                Positioned(
                  bottom: 48,
                  left: 0,
                  right: 0,
                  child: Text(
                    'Empowering Malawian students',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ).animate(delay: 800.ms).fadeIn(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedBookIcon extends StatelessWidget {
  final AnimationController pulseCtrl;

  const _AnimatedBookIcon({required this.pulseCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (context, _) {
        final scale = 1.0 + (pulseCtrl.value * 0.05);
        final opacity = 0.8 + (pulseCtrl.value * 0.2);
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PremiumLoader extends StatelessWidget {
  final AnimationController pulseCtrl;

  const _PremiumLoader({required this.pulseCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (context, _) {
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3 - (pulseCtrl.value * 0.2)),
              width: 2.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withValues(alpha: 0.5 + (pulseCtrl.value * 0.5)),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Orb extends StatelessWidget {
  final int index;
  final AnimationController controller;

  const _Orb(this.index, this.controller);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final phase = (index / 3) * 2 * math.pi;
        final x = controller.value * 2 * math.pi + phase;
        return Positioned(
          left: (math.sin(x) * 0.4 + 0.5) * MediaQuery.of(context).size.width -
              40,
          top: (math.cos(x * 0.7) * 0.3 + 0.3) *
                  MediaQuery.of(context).size.height -
              40,
          child: Container(
            width: 80 + (index * 30),
            height: 80 + (index * 30),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (index == 0
                      ? const Color(0xFF2EC4B6)
                      : index == 1
                          ? const Color(0xFF7C4DFF)
                          : const Color(0xFFF4A261))
                  .withValues(alpha: 0.08),
            ),
          ),
        );
      },
    );
  }
}
