import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';

// ─── Camera initialisation provider ───────────────────────────────────────────
final _cameraControllerProvider =
    StateNotifierProvider.autoDispose<_CameraNotifier, AsyncValue<CameraController>>(
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
      final camera = cameras.first;
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

// ─── Screen ───────────────────────────────────────────────────────────────────
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});
  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with SingleTickerProviderStateMixin {
  File? _capturedImage;
  String _educationLevel = 'secondary';
  String _subject = '';
  String _examType = '';
  String _year = '';
  bool _solving = false;
  bool _flashOn = false;
  double _zoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 4.0;
  double _baseZoom = 1.0;
  late AnimationController _shutterAnim;

  @override
  void initState() {
    super.initState();
    _shutterAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _shutterAnim.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _capture(CameraController ctrl) async {
    if (!ctrl.value.isInitialized || _solving) return;
    _shutterAnim.forward(from: 0);
    HapticFeedback.lightImpact();
    try {
      final xfile = await ctrl.takePicture();
      setState(() => _capturedImage = File(xfile.path));
    } catch (_) {}
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, maxWidth: 2048, maxHeight: 2048);
    if (x != null && mounted) setState(() => _capturedImage = File(x.path));
  }

  Future<void> _toggleFlash(CameraController ctrl) async {
    try {
      final next = _flashOn ? FlashMode.off : FlashMode.torch;
      await ctrl.setFlashMode(next);
      setState(() => _flashOn = !_flashOn);
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (_capturedImage == null) return;
    setState(() => _solving = true);
    try {
      final client = ref.read(graphqlClientProvider);
      final bytes = await _capturedImage!.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        if (mounted) {
          _showSnack('Image too large (max 5 MB). Try a smaller photo.', isError: true);
          setState(() => _solving = false);
        }
        return;
      }
      final b64 = base64Encode(bytes);
      final result = await client.mutate(MutationOptions(
        document: gql(kSubmitScanSession),
        variables: {
          'imageBase64': b64,
          'fileName': _capturedImage!.path.split('/').last,
          'subject': _subject.trim(),
          'educationLevel': _educationLevel,
          'examType': _examType.trim(),
          'year': int.tryParse(_year),
        },
      ));
      if (!mounted) return;
      setState(() => _solving = false);
      if (result.hasException || result.data?['submitScanSession'] == null) {
        _showSnack(
          result.exception?.graphqlErrors.firstOrNull?.message ?? 'Failed to solve paper',
          isError: true,
        );
        return;
      }
      final data = result.data!['submitScanSession'];
      if (data['success'] != true) {
        _showSnack(
          (data['errors'] as List?)?.firstOrNull?.toString() ?? 'Failed',
          isError: true,
        );
        return;
      }
      context.push('/scanner/results', extra: {'solutions': data['session']?['solutions'] ?? []});
    } catch (e) {
      if (!mounted) return;
      setState(() => _solving = false);
      _showSnack('Error: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? DesignTokens.error : DesignTokens.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final camState = ref.watch(_cameraControllerProvider);
    return camState.when(
      loading: () => const _LoadingScaffold(),
      error: (e, _) => _ErrorScaffold(message: e.toString()),
      data: (ctrl) => _capturedImage != null
          ? _PreviewSheet(
              image: _capturedImage!,
              educationLevel: _educationLevel,
              subject: _subject,
              examType: _examType,
              year: _year,
              solving: _solving,
              onLevelChanged: (v) => setState(() => _educationLevel = v),
              onSubjectChanged: (v) => _subject = v,
              onExamChanged: (v) => _examType = v,
              onYearChanged: (v) => _year = v,
              onRetake: () => setState(() => _capturedImage = null),
              onSubmit: _submit,
            )
          : _LiveViewport(
              ctrl: ctrl,
              flashOn: _flashOn,
              zoom: _zoom,
              minZoom: _minZoom,
              maxZoom: _maxZoom,
              shutterAnim: _shutterAnim,
              onCapture: () => _capture(ctrl),
              onGallery: _pickFromGallery,
              onFlash: () => _toggleFlash(ctrl),
              onClose: () => context.pop(),
              onScaleStart: (_) => _baseZoom = _zoom,
              onScaleUpdate: (d) async {
                final newZoom = (_baseZoom * d.scale).clamp(_minZoom, _maxZoom);
                try {
                  await ctrl.setZoomLevel(newZoom);
                  setState(() => _zoom = newZoom);
                } catch (_) {}
              },
            ),
    );
  }
}

// ─── Live camera viewport ─────────────────────────────────────────────────────
class _LiveViewport extends StatefulWidget {
  final CameraController ctrl;
  final bool flashOn;
  final double zoom, minZoom, maxZoom;
  final AnimationController shutterAnim;
  final VoidCallback onCapture, onGallery, onFlash, onClose;
  final void Function(ScaleStartDetails) onScaleStart;
  final void Function(ScaleUpdateDetails) onScaleUpdate;

  const _LiveViewport({
    required this.ctrl,
    required this.flashOn,
    required this.zoom,
    required this.minZoom,
    required this.maxZoom,
    required this.shutterAnim,
    required this.onCapture,
    required this.onGallery,
    required this.onFlash,
    required this.onClose,
    required this.onScaleStart,
    required this.onScaleUpdate,
  });

  @override
  State<_LiveViewport> createState() => _LiveViewportState();
}

class _LiveViewportState extends State<_LiveViewport> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview fills full screen
          GestureDetector(
            onScaleStart: widget.onScaleStart,
            onScaleUpdate: widget.onScaleUpdate,
            child: ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: size.width,
                  height: size.width * (widget.ctrl.value.aspectRatio == 0
                      ? 1.78
                      : 1 / widget.ctrl.value.aspectRatio),
                  child: CameraPreview(widget.ctrl),
                ),
              ),
            ),
          ),

          // Shutter flash
          AnimatedBuilder(
            animation: widget.shutterAnim,
            builder: (_, __) => Opacity(
              opacity: (1 - widget.shutterAnim.value) * 0.7,
              child: widget.shutterAnim.value < 0.01
                  ? const SizedBox.shrink()
                  : Container(color: Colors.white),
            ),
          ),

          // Corner guides overlay
          const _ScanGuide(),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CamIconBtn(
                    icon: Icons.close,
                    onTap: widget.onClose,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Magic Scanner',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                  _CamIconBtn(
                    icon: widget.flashOn ? Icons.flash_on : Icons.flash_off,
                    onTap: widget.onFlash,
                    active: widget.flashOn,
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Point at your question paper',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Gallery
                        _CamIconBtn(
                          icon: Icons.photo_library_outlined,
                          onTap: widget.onGallery,
                          size: 48,
                        ),
                        // Shutter
                        GestureDetector(
                          onTap: widget.onCapture,
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Placeholder for symmetry
                        const SizedBox(width: 48, height: 48),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Zoom indicator
          if (widget.zoom > 1.05)
            Positioned(
              bottom: 140,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.zoom.toStringAsFixed(1)}×',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Corner scan guide overlay ────────────────────────────────────────────────
class _ScanGuide extends StatelessWidget {
  const _ScanGuide();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.82,
        heightFactor: 0.52,
        child: CustomPaint(painter: _CornerPainter()),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const len = 28.0;
    final r = 8.0;
    // top-left
    canvas.drawLine(Offset(r, 0), Offset(len, 0), paint);
    canvas.drawLine(Offset(0, r), Offset(0, len), paint);
    // top-right
    canvas.drawLine(Offset(size.width - len, 0), Offset(size.width - r, 0), paint);
    canvas.drawLine(Offset(size.width, r), Offset(size.width, len), paint);
    // bottom-left
    canvas.drawLine(Offset(0, size.height - len), Offset(0, size.height - r), paint);
    canvas.drawLine(Offset(r, size.height), Offset(len, size.height), paint);
    // bottom-right
    canvas.drawLine(Offset(size.width - len, size.height), Offset(size.width - r, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - len), Offset(size.width, size.height - r), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Preview + form sheet ─────────────────────────────────────────────────────
class _PreviewSheet extends StatelessWidget {
  final File image;
  final String educationLevel, subject, examType, year;
  final bool solving;
  final void Function(String) onLevelChanged;
  final void Function(String) onSubjectChanged;
  final void Function(String) onExamChanged;
  final void Function(String) onYearChanged;
  final VoidCallback onRetake, onSubmit;

  const _PreviewSheet({
    required this.image,
    required this.educationLevel,
    required this.subject,
    required this.examType,
    required this.year,
    required this.solving,
    required this.onLevelChanged,
    required this.onSubjectChanged,
    required this.onExamChanged,
    required this.onYearChanged,
    required this.onRetake,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Photo preview — takes upper half
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(image, fit: BoxFit.cover),
                // Gradient overlay at bottom of photo
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  height: 80,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                ),
                // Retake button
                SafeArea(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _CamIconBtn(icon: Icons.refresh, onTap: onRetake),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Form section — slides up
          Expanded(
            flex: 6,
            child: Container(
              decoration: BoxDecoration(
                color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: DesignTokens.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tell us about this paper',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'The more context you give, the better the AI solves it.',
                      style: theme.textTheme.bodySmall?.copyWith(color: DesignTokens.textSecondary),
                    ),
                    const SizedBox(height: 20),

                    // Level chips
                    _LevelSelector(
                      selected: educationLevel,
                      onChanged: onLevelChanged,
                    ),
                    const SizedBox(height: 16),

                    // Subject
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Subject',
                        hintText: _subjectHint(educationLevel),
                        prefixIcon: const Icon(Icons.book_outlined, size: 20),
                      ),
                      onChanged: onSubjectChanged,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),

                    // Exam type + year row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Exam type',
                              hintText: _examHint(educationLevel),
                            ),
                            onChanged: onExamChanged,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(labelText: 'Year'),
                            keyboardType: TextInputType.number,
                            onChanged: onYearChanged,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: solving ? null : onSubmit,
                        icon: solving
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: Text(solving ? 'Solving…' : 'Solve This Paper'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignTokens.primary,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                          ),
                        ),
                      ),
                    ),
                  ]
                      .animate(interval: 40.ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.04, end: 0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _subjectHint(String level) {
    switch (level) {
      case 'primary': return 'e.g. Maths, English, Science';
      case 'tertiary': return 'e.g. Organic Chemistry, Calculus';
      default: return 'e.g. Biology, Mathematics, History';
    }
  }

  static String _examHint(String level) {
    switch (level) {
      case 'primary': return 'e.g. PSLCE';
      case 'tertiary': return 'e.g. Final, Midterm';
      default: return 'e.g. MSCE, Final';
    }
  }
}

// ─── Level selector chips ─────────────────────────────────────────────────────
class _LevelSelector extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;

  const _LevelSelector({required this.selected, required this.onChanged});

  static const _levels = [
    ('primary', 'Primary', Icons.school_outlined),
    ('secondary', 'Secondary', Icons.menu_book_outlined),
    ('tertiary', 'Tertiary', Icons.account_balance_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _levels.map((l) {
        final isSelected = selected == l.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(l.$1),
              child: AnimatedContainer(
                duration: DesignTokens.durFast,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? DesignTokens.primary.withValues(alpha: 0.12)
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  border: Border.all(
                    color: isSelected ? DesignTokens.primary : DesignTokens.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(l.$3, size: 18, color: isSelected ? DesignTokens.primary : DesignTokens.textSecondary),
                    const SizedBox(height: 4),
                    Text(
                      l.$2,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? DesignTokens.primary : DesignTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Icon button for camera overlay ──────────────────────────────────────────
class _CamIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final double size;

  const _CamIconBtn({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: active ? Colors.amber.withValues(alpha: 0.85) : Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.44),
      ),
    );
  }
}

// ─── Loading / error scaffolds ────────────────────────────────────────────────
class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  final String message;
  const _ErrorScaffold({required this.message});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 64),
              const SizedBox(height: 16),
              Text(
                'Camera not available',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(message, style: const TextStyle(color: Colors.white54), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                label: const Text('Go back', style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white38)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
