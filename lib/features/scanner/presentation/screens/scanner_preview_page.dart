import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'scanner_image_preview.dart';
import 'scanner_preview_form.dart';

class ScannerPreviewPage extends ConsumerStatefulWidget {
  final File image;
  final VoidCallback onBack;

  const ScannerPreviewPage({
    super.key,
    required this.image,
    required this.onBack,
  });

  @override
  ConsumerState<ScannerPreviewPage> createState() => _ScannerPreviewPageState();
}

class _ScannerPreviewPageState extends ConsumerState<ScannerPreviewPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _laserAnim;
  bool _solving = false;

  @override
  void initState() {
    super.initState();
    _laserAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserAnim.dispose();
    super.dispose();
  }

  void _onSolvingChanged(bool v) => setState(() => _solving = v);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solve Paper',
            style: TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  ScannerImagePreview(
                    image: widget.image,
                    laserAnimation: _laserAnim,
                    solving: _solving,
                  ),
                  const SizedBox(height: 32),
                  ScannerDetailsForm(
                    image: widget.image,
                    onSolvingChanged: _onSolvingChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
