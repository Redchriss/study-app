import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class ScannerLandingPage extends StatelessWidget {
  final VoidCallback onSnapToSolve;
  final VoidCallback onUploadToSolve;

  const ScannerLandingPage({
    super.key,
    required this.onSnapToSolve,
    required this.onUploadToSolve,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Paper Solver',
            style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                'How would you like to solve your past paper?',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                'Point your camera at a single question or upload a full past paper page. Our AI will break it down and solve it.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: 15,
                    height: 1.4),
              ),
              const SizedBox(height: 48),
              Expanded(
                child: AnimatedPress(
                  onTap: onSnapToSolve,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFC107).withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.document_scanner_rounded,
                              size: 56, color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        const Text('Snap to Solve',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.black87)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome,
                                  color: Color(0xFFFFD54F), size: 12),
                              SizedBox(width: 4),
                              Text('AI POWERED',
                                  style: TextStyle(
                                      color: Color(0xFFFFD54F),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: AnimatedPress(
                  onTap: onUploadToSolve,
                  child: Container(
                    decoration: BoxDecoration(
                      color: dark ? DesignTokens.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                          color: DesignTokens.primary.withValues(alpha: 0.2),
                          width: 2),
                      boxShadow: DesignTokens.shadowSm(dark),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: DesignTokens.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.photo_library_rounded,
                              size: 56, color: DesignTokens.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Upload to Solve',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: dark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
