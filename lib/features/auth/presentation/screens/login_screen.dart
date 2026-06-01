import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
              const LoginForm(),
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
          colors: [Color(0xFF1B6CA8), Color(0xFF0E3D6E)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            child: const Icon(Icons.auto_stories_rounded,
                size: 40, color: Colors.white),
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
          ),
          const SizedBox(height: 8),
          Text(
            'Log in to continue studying',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
