import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/theme/design_tokens.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _listen());
  }

  void _listen() {
    ref.listen(authProvider, (prev, next) {
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
            const Text('Learn. Grow. Pass.',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
