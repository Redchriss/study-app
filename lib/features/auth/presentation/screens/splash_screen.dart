import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  Timer? _timeoutTimer;
  bool _showSlowHint = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.3, 0.7, curve: Curves.easeOut)),
    );
    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _listen());

    _timeoutTimer = Timer(const Duration(seconds: 20), () {
      if (!mounted) return;
      context.go('/onboarding');
    });
    // Show slow connection hint after 5s
    Timer(const Duration(seconds: 5), () {
      if (mounted && ref.read(authProvider).isLoading) {
        setState(() => _showSlowHint = true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _listen() {
    ref.listen(authProvider, (prev, next) {
      if (!next.isLoading && !next.biometricRequired) {
        _timeoutTimer?.cancel();
      }
      if (!next.biometricRequired) return;
      WidgetsBinding.instance.addPostFrameCallback((_) => _doBiometric());
    });
  }

  Future<void> _doBiometric() async {
    final authenticated = await BiometricService().authenticate();
    if (!mounted) return;
    if (authenticated) {
      await ref.read(authProvider.notifier).completeBiometric();
    } else {
      await ref.read(authProvider.notifier).failBiometric();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.primary,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  DesignTokens.primaryLight
                      .withValues(alpha: 0.4 + _controller.value * 0.2),
                  DesignTokens.primary,
                  const Color(0xFF0A2A44),
                ],
              ),
            ),
            child: child,
          );
        },
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: _scaleAnim.value,
                    child: Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, Color(0xFFE0E8F0)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 40,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_stories_rounded,
                        size: 56,
                        color: DesignTokens.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Opacity(
                    opacity: _fadeAnim.value,
                    child: const Text(
                      'Yaza',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Opacity(
                    opacity: (_fadeAnim.value * 0.75).clamp(0.0, 1.0),
                    child: Text(
                      'Learn. Grow. Pass.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.12,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Opacity(
                    opacity: _controller.value > 0.6
                        ? ((_controller.value - 0.6) / 0.4).clamp(0.0, 1.0)
                        : 0.0,
                    child: const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          color: Colors.white54,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                  ),
                  if (_showSlowHint) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Connecting to server...',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
