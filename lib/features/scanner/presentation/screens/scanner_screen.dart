import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

final _cameraControllerProvider = StateNotifierProvider.autoDispose<_CameraNotifier, AsyncValue<CameraController>>(
  (ref) => _CameraNotifier(),
);

class _CameraNotifier extends StateNotifier<AsyncValue<CameraController>> {
  _CameraNotifier() : super(const AsyncValue.loading()) { _init(); }
  CameraController? _ctrl;
  Future<void> _init() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        state = AsyncValue.error('No cameras found', StackTrace.current);
        return;
      }
      final camera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cameras.first);
      final ctrl = CameraController(camera, ResolutionPreset.high, enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);
      await ctrl.initialize();
      _ctrl = ctrl;
      if (mounted) state = AsyncValue.data(ctrl);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  @override
  void dispose() { _ctrl?.dispose(); super.dispose(); }
}

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});
  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> with TickerProviderStateMixin {
  String _step = 'landing'; // landing, camera, preview
  File? _capturedImage;
  
  String? _educationLevel;
  String? _subject;
  List? _subjects;
  bool _loadingSubjects = false;
  String _examType = '';
  String _year = '';
  
  bool _solving = false;
  bool _flashOn = false;
  double _zoom = 1.0;
  
  late AnimationController _laserAnim;

  @override
  void initState() {
    super.initState();
    _laserAnim = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_educationLevel == null) {
      final auth = ref.read(authProvider);
      _educationLevel = auth.user?['profile']?['educationLevel']?.toString() ?? 'secondary';
      _loadSubjects();
    }
  }

  @override
  void dispose() {
    _laserAnim.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    final level = _educationLevel ?? 'secondary';
    setState(() { _loadingSubjects = true; _subject = null; });
    try {
      final client = ref.read(graphqlClientProvider);
      final result = await client.query(QueryOptions(document: gql(kSubjects), variables: {'educationLevel': level}, fetchPolicy: FetchPolicy.cacheFirst));
      if (!mounted) return;
      if (result.hasException) { setState(() => _loadingSubjects = false); return; }
      setState(() { _subjects = (result.data?['subjects'] as List?) ?? []; _loadingSubjects = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingSubjects = false);
    }
  }

  Future<void> _pickGallery() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 2048, maxHeight: 2048);
    if (x != null && mounted) setState(() { _capturedImage = File(x.path); _step = 'preview'; });
  }

  Future<void> _submit() async {
    if (_capturedImage == null) return;
    setState(() => _solving = true);
    try {
      final client = ref.read(graphqlClientProvider);
      final bytes = await _capturedImage!.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image too large (max 5MB)'), backgroundColor: DesignTokens.error));
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
          'subject': _subject?.trim() ?? '',
          'educationLevel': _educationLevel ?? 'secondary',
          'examType': _examType.trim(),
          'year': int.tryParse(_year),
        },
      ));
      if (!mounted) return;
      setState(() => _solving = false);
      if (result.hasException || result.data?['submitScanSession'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.exception?.graphqlErrors.firstOrNull?.message ?? 'Failed to solve'), backgroundColor: DesignTokens.error));
        return;
      }
      final data = result.data!['submitScanSession'];
      if (data['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((data['errors'] as List?)?.firstOrNull?.toString() ?? 'Failed'), backgroundColor: DesignTokens.error));
        return;
      }
      context.push('/scanner/results', extra: {'solutions': data['session']?['solutions'] ?? []});
    } catch (e) {
      if (mounted) {
        setState(() => _solving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: DesignTokens.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 'landing') return _buildLanding();
    if (_step == 'camera') return _buildCamera();
    return _buildPreview();
  }

  Widget _buildLanding() {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Magic Scanner', style: TextStyle(fontWeight: FontWeight.w800)),
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
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                'Point your camera at a question, or upload a photo/screenshot from your gallery.',
                textAlign: TextAlign.center,
                style: TextStyle(color: DesignTokens.textSecondary, fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 48),
              Expanded(
                child: AnimatedPress(
                  onTap: () => setState(() => _step = 'camera'),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFFFC107).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded, size: 56, color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        const Text('Scan with Camera', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: AnimatedPress(
                  onTap: _pickGallery,
                  child: Container(
                    decoration: BoxDecoration(
                      color: dark ? DesignTokens.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: DesignTokens.primary.withValues(alpha: 0.2), width: 2),
                      boxShadow: DesignTokens.shadowSm(dark),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: DesignTokens.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.photo_library_rounded, size: 56, color: DesignTokens.primary),
                        ),
                        const SizedBox(height: 16),
                        Text('Upload from Gallery', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: dark ? Colors.white : Colors.black87)),
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

  Widget _buildCamera() {
    final camState = ref.watch(_cameraControllerProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                    onPressed: () => setState(() => _step = 'landing'),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFFFFC107).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFC107), size: 16),
                        SizedBox(width: 8),
                        Text('Magic Scanner', style: TextStyle(color: Color(0xFFFFC107), fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(_flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded, color: _flashOn ? const Color(0xFFFFC107) : Colors.white, size: 28),
                    onPressed: () async {
                      final ctrl = ref.read(_cameraControllerProvider).valueOrNull;
                      if (ctrl != null) {
                        final next = _flashOn ? FlashMode.off : FlashMode.torch;
                        await ctrl.setFlashMode(next);
                        setState(() => _flashOn = !_flashOn);
                      }
                    },
                  ),
                ],
              ),
            ),
            
            // Viewfinder
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
                    loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107))),
                    error: (e, _) => Center(child: Text('Camera error: $e', style: const TextStyle(color: Colors.white))),
                    data: (ctrl) => Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(ctrl),
                        // Corner Guides
                        Center(
                          child: FractionallySizedBox(
                            widthFactor: 0.8, heightFactor: 0.6,
                            child: CustomPaint(painter: _CornerPainter()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Bottom Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                children: [
                  // Zoom Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [1.0, 2.0, 3.0].map((z) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: GestureDetector(
                        onTap: () async {
                          final ctrl = ref.read(_cameraControllerProvider).valueOrNull;
                          if (ctrl != null) {
                            await ctrl.setZoomLevel(z);
                            setState(() => _zoom = z);
                          }
                        },
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: _zoom == z ? const Color(0xFFFFC107) : Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(child: Text('${z.toInt()}x', style: TextStyle(color: _zoom == z ? Colors.black : Colors.white, fontWeight: FontWeight.w800))),
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Shutter Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 32),
                        onPressed: _pickGallery,
                      ),
                      GestureDetector(
                        onTap: () async {
                          final ctrl = ref.read(_cameraControllerProvider).valueOrNull;
                          if (ctrl != null && ctrl.value.isInitialized) {
                            HapticFeedback.heavyImpact();
                            final xfile = await ctrl.takePicture();
                            setState(() { _capturedImage = File(xfile.path); _step = 'preview'; });
                          }
                        },
                        child: Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFFFC107), width: 4),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Container(
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Balance spacing
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

  Widget _buildPreview() {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solve Paper', style: TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() { _step = 'landing'; _capturedImage = null; }),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Image with Laser Overlay
                  Container(
                    height: 240,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: DesignTokens.primary.withValues(alpha: 0.2), width: 2),
                      boxShadow: DesignTokens.shadowSm(dark),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_capturedImage != null)
                            Image.file(
                              _capturedImage!, 
                              fit: BoxFit.cover,
                              color: _solving ? const Color(0xFF10B981).withValues(alpha: 0.2) : null,
                              colorBlendMode: _solving ? BlendMode.overlay : null,
                            ),
                          if (_solving)
                            AnimatedBuilder(
                              animation: _laserAnim,
                              builder: (context, child) {
                                return Positioned(
                                  top: _laserAnim.value * 220,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      boxShadow: [
                                        BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.8), blurRadius: 15, spreadRadius: 5),
                                        BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 10),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            ),
                          if (_solving)
                            Container(
                              color: Colors.black.withValues(alpha: 0.4),
                              child: const Center(
                                child: Text('Scanning Document...', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Form
                  Text('Paper Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Help the AI understand what it is looking at.', style: TextStyle(color: DesignTokens.textSecondary, fontSize: 13)),
                  const SizedBox(height: 20),
                  
                  // Level Chips
                  Row(
                    children: [
                      _LevelChip(label: 'Primary', icon: Icons.child_care_rounded, selected: _educationLevel == 'primary', onTap: () { setState(() => _educationLevel = 'primary'); _loadSubjects(); }),
                      const SizedBox(width: 8),
                      _LevelChip(label: 'Secondary', icon: Icons.menu_book_rounded, selected: _educationLevel == 'secondary', onTap: () { setState(() => _educationLevel = 'secondary'); _loadSubjects(); }),
                      const SizedBox(width: 8),
                      _LevelChip(label: 'Tertiary', icon: Icons.account_balance_rounded, selected: _educationLevel == 'tertiary', onTap: () { setState(() => _educationLevel = 'tertiary'); _loadSubjects(); }),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  if (_loadingSubjects)
                    const Center(child: CircularProgressIndicator())
                  else
                    DropdownButtonFormField<String>(
                      key: ValueKey('scanner_subject_${_subjects?.length}_$_subject'),
                      value: _subject,
                      decoration: InputDecoration(
                        labelText: 'Subject',
                        filled: true,
                        fillColor: dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.book_outlined),
                      ),
                      items: (_subjects ?? []).map((s) => DropdownMenuItem<String>(
                        value: s['name']?.toString(),
                        child: Text(s['name']?.toString() ?? ''),
                      )).toList(),
                      onChanged: (v) => setState(() => _subject = v),
                    ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Exam type (e.g. MSCE)',
                            filled: true,
                            fillColor: dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                          onChanged: (v) => _examType = v,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Year',
                            filled: true,
                            fillColor: dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => _year = v,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Submit Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _solving ? null : _submit,
                  icon: _solving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(_solving ? 'Solving...' : 'Solve This Paper', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _LevelChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? DesignTokens.primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? DesignTokens.primary : DesignTokens.textTertiary.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: selected ? DesignTokens.primary : DesignTokens.textSecondary),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? DesignTokens.primary : DesignTokens.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFFC107)..strokeWidth = 4..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    const len = 32.0;
    const r = 16.0;
    canvas.drawLine(const Offset(r, 0), const Offset(len, 0), paint);
    canvas.drawLine(const Offset(0, r), const Offset(0, len), paint);
    canvas.drawLine(Offset(size.width - len, 0), Offset(size.width - r, 0), paint);
    canvas.drawLine(Offset(size.width, r), Offset(size.width, len), paint);
    canvas.drawLine(Offset(0, size.height - len), Offset(0, size.height - r), paint);
    canvas.drawLine(Offset(r, size.height), Offset(len, size.height), paint);
    canvas.drawLine(Offset(size.width - len, size.height), Offset(size.width - r, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - len), Offset(size.width, size.height - r), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}