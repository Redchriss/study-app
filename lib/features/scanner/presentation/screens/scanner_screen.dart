import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'scanner_landing_page.dart';
import 'scanner_camera_page.dart';
import 'scanner_preview_page.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});
  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  String _step = 'landing';
  File? _capturedImage;

  Future<void> _pickGallery() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (x != null && mounted) {
      setState(() {
        _capturedImage = File(x.path);
        _step = 'preview';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_step) {
      case 'camera':
        return ScannerCameraPage(
          onBack: () => setState(() => _step = 'landing'),
          onCapture: (f) => setState(() {
            _capturedImage = f;
            _step = 'preview';
          }),
          onPickGallery: _pickGallery,
        );
      case 'preview':
        return ScannerPreviewPage(
          image: _capturedImage!,
          onBack: () => setState(() {
            _step = 'landing';
            _capturedImage = null;
          }),
        );
      default:
        return ScannerLandingPage(
          onSnapToSolve: () => setState(() => _step = 'camera'),
          onUploadToSolve: _pickGallery,
        );
    }
  }
}
