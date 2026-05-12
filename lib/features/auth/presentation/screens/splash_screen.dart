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
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (_, next) {
      next.whenData((auth) {
        if (!auth.isLoading) {
          if (auth.isAuthenticated) {
            final profile = auth.user?['profile'];
            if (profile?['onboardingComplete'] == true) {
              context.go('/home');
            } else {
              context.go('/setup');
            }
          } else {
            context.go('/onboarding');
          }
        }
      });
      next.whenError((error, _) {
        if (mounted) setState(() => _timedOut = true);
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
            if (_timedOut)
              Column(
                children: [
                  const Text('Could not connect to server', style: TextStyle(color: Colors.white60)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _timedOut = false);
                      ref.invalidate(authProvider);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                    child: const Text('Retry', style: TextStyle(color: Color(0xFF1B6CA8))),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Go to Login', style: TextStyle(color: Colors.white70)),
                  ),
                ],
              )
            else
              const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
