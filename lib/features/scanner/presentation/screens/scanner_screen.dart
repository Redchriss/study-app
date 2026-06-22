import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  // Upload a full past paper as a PDF or a photo (JPG/PNG), mirroring the
  // web "AI Paper Solver" which accepts PDF/JPG/PNG up to 10MB.
  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    final path = result?.files.single.path;
    if (path != null && mounted) {
      setState(() {
        _capturedImage = File(path);
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
          onPickGallery: _pickDocument,
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
          onUploadToSolve: _pickDocument,
        );
    }
  }
}
