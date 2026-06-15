import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'scanner_camera_provider.dart';
import 'scanner_shared_widgets.dart';

class ScannerCameraPage extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  final ValueChanged<File> onCapture;
  final VoidCallback onPickGallery;

  const ScannerCameraPage({
    super.key,
    required this.onBack,
    required this.onCapture,
    required this.onPickGallery,
  });

  @override
  ConsumerState<ScannerCameraPage> createState() => _ScannerCameraPageState();
}

class _ScannerCameraPageState extends ConsumerState<ScannerCameraPage> {
  bool _flashOn = false;
  double _zoom = 1.0;

  @override
  Widget build(BuildContext context) {
    final camState = ref.watch(cameraControllerProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 28),
                    onPressed: widget.onBack,
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_stories_rounded,
                            color: Color(0xFFFFC107), size: 16),
                        SizedBox(width: 8),
                        Text('AI Paper Solver',
                            style: TextStyle(
                                color: Color(0xFFFFC107),
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _flashOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      color: _flashOn ? const Color(0xFFFFC107) : Colors.white,
                      size: 28,
                    ),
                    onPressed: () async {
                      final ctrl =
                          ref.read(cameraControllerProvider).valueOrNull;
                      if (ctrl != null) {
                        await ctrl.setFlashMode(
                            _flashOn ? FlashMode.off : FlashMode.torch);
                        setState(() => _flashOn = !_flashOn);
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0xFFFFC107), width: 3),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(29),
                  child: camState.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFFFFC107))),
                    error: (e, _) => Center(
                        child: Text('Camera error: $e',
                            style: const TextStyle(color: Colors.white))),
                    data: (ctrl) => Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(ctrl),
                        Center(
                          child: FractionallySizedBox(
                            widthFactor: 0.8,
                            heightFactor: 0.6,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                    child:
                                        CustomPaint(painter: CornerPainter())),
                                const Center(
                                  child: Text(
                                    'Aim at a question to solve',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [1.0, 2.0, 3.0]
                        .map((z) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: GestureDetector(
                                onTap: () async {
                                  final ctrl = ref
                                      .read(cameraControllerProvider)
                                      .valueOrNull;
                                  if (ctrl != null) {
                                    await ctrl.setZoomLevel(z);
                                    setState(() => _zoom = z);
                                  }
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _zoom == z
                                        ? const Color(0xFFFFC107)
                                        : Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                      child: Text(
                                    '${z.toInt()}x',
                                    style: TextStyle(
                                      color: _zoom == z
                                          ? Colors.black
                                          : Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  )),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.photo_library_rounded,
                            color: Colors.white, size: 32),
                        onPressed: widget.onPickGallery,
                      ),
                      GestureDetector(
                        onTap: () async {
                          final ctrl =
                              ref.read(cameraControllerProvider).valueOrNull;
                          if (ctrl != null && ctrl.value.isInitialized) {
                            HapticFeedback.heavyImpact();
                            final xfile = await ctrl.takePicture();
                            widget.onCapture(File(xfile.path));
                          }
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFFFFC107), width: 4),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Container(
                              decoration: const BoxDecoration(
                                  color: Colors.white, shape: BoxShape.circle),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
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
