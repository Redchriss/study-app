import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/design_tokens.dart';
import 'login_form.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(size),
              const LoginForm().animate().fadeIn(
                    delay: 400.ms,
                    duration: 600.ms,
                    curve: Curves.easeOut,
                  ).slideY(begin: 0.05),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Size size) {
    return Container(
      width: double.infinity,
      height: size.height * 0.34,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.6, 1.0],
          colors: [
            Color(0xFF1B6CA8),
            Color(0xFF155885),
            Color(0xFF0E3D6E),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(48),
          bottomRight: Radius.circular(48),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x331B6CA8),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon
          Container(
            width: 80,
            height: 80,
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
              size: 44,
              color: Colors.white,
            ),
          ).animate().scale(
                duration: 600.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: 20),
          const Text(
            'Welcome back',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -1.2,
            ),
          ).animate().fadeIn(
                duration: 500.ms,
                curve: Curves.easeOut,
              ).slideY(begin: 0.1),
          const SizedBox(height: 8),
          Text(
            'Log in to continue studying',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ).animate(delay: 200.ms).fadeIn(),
        ],
      ),
    );
  }
}
