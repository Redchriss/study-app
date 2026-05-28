import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cameraControllerProvider = StateNotifierProvider.autoDispose<
    _CameraNotifier, AsyncValue<CameraController>>(
  (ref) => _CameraNotifier(),
);

class _CameraNotifier extends StateNotifier<AsyncValue<CameraController>> {
  _CameraNotifier() : super(const AsyncValue.loading()) {
    _init();
  }
  CameraController? _ctrl;

  Future<void> _init() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        state = AsyncValue.error('No cameras found', StackTrace.current);
        return;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final ctrl = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await ctrl.initialize();
      _ctrl = ctrl;
      if (mounted) state = AsyncValue.data(ctrl);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }
}
