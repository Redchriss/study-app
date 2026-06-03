import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../providers/auth_provider.dart';

/// Minimal splash — just shows the logo while auth bootstraps.
/// Router handles all navigation — this screen does nothing except
/// trigger biometric if required.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _listen());
    // Hard timeout — go to login if stuck for 15s
    _timeoutTimer = Timer(const Duration(seconds: 15), () {
      if (mounted) context.go('/login');
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
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
    return Scaffold(
      backgroundColor: DesignTokens.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.auto_stories_rounded,
                  size: 48, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'Yaza',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  color: Colors.white54, strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
