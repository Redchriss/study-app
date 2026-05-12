import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Force navigate to login after 15 seconds no matter what
    // This catches any case where auth never resolves
    Future.delayed(const Duration(seconds: 15), () {
      if (!mounted) return;
      // Check current auth state
      try {
        final auth = ref.read(authProvider).valueOrNull;
        if (auth == null || auth.isLoading) {
          // Auth never resolved — force navigate
          context.go('/onboarding');
        }
      } catch (_) {
        // ref.read failed — force navigate
        context.go('/onboarding');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes
    ref.listen<AsyncValue>(authProvider, (_, next) {
      next.whenData((auth) {
        if (!auth.isLoading && mounted) {
          if (auth.isAuthenticated) {
            final profile = auth.user?['profile'];
            context.go(profile?['onboardingComplete'] == true ? '/home' : '/setup');
          } else {
            context.go('/onboarding');
          }
        }
      });
    });

    return Scaffold(
      backgroundColor: const Color(0xFF1B6CA8),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 80, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'Yaza',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Learn. Grow. Pass.', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
