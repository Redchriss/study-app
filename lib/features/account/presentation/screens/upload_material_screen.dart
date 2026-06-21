import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'upload_material_manager.dart';
import 'upload_step_type.dart';
import 'upload_step_subject.dart';
import 'upload_step_content.dart';
import 'upload_step_review.dart';

class UploadMaterialScreen extends ConsumerStatefulWidget {
  const UploadMaterialScreen({super.key});
  @override
  ConsumerState<UploadMaterialScreen> createState() =>
      _UploadMaterialScreenState();
}

class _UploadMaterialScreenState extends ConsumerState<UploadMaterialScreen> {
  final _m = UploadMaterialManager();
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _m.attach(
      ref: ref,
      setState: (fn) => setState(fn),
      isMounted: () => mounted,
    );
    _m.captureProfile(ref);
    final level = ref.read(authProvider).user?['profile']?['educationLevel']?.toString();
    _m.updateEducationLevel(level);
    _m.loadSubjects(programId: _m.profileProgramId);
  }

  @override
  void dispose() {
    _m.dispose();
    super.dispose();
  }

  bool get _canGoNext {
    switch (_step) {
      case 0:
        return _m.contentType.isNotEmpty;
      case 1:
        return _m.subjectId != null;
      case 2:
        return _m.titleCtrl.text.trim().isNotEmpty && _hasContent;
      case 3:
        return true;
      default:
        return false;
    }
  }

  bool get _hasContent {
    if (_m.requiresFile) return _m.selectedFile != null;
    if (_m.contentType == 'video') return _m.youtubeCtrl.text.trim().isNotEmpty;
    if (_m.contentType == 'text') {
      return _m.textCtrl.text.trim().isNotEmpty || _m.selectedFile != null;
    }
    return _m.selectedFile != null;
  }

  void _next() {
    if (!_canGoNext) return;
    HapticService.lightTap();
    setState(() => _step++);
  }

  void _back() {
    if (_step <= 0) return;
    HapticService.lightTap();
    setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Material',
            style: TextStyle(fontWeight: FontWeight.w800)),
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _back,
              )
            : null,
      ),
      body: Column(
        children: [
          _StepIndicator(current: _step, total: 4),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: AnimatedSwitcher(
                duration: DesignTokens.durFast,
                child: _buildStep(),
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return UploadStepType(
          key: const ValueKey('step_type'),
          selected: _m.contentType,
          onChanged: (v) => setState(() => _m.changeType(v)),
        );
      case 1:
        return UploadStepSubject(
          key: const ValueKey('step_subject'),
          manager: _m,
          onSubjectChanged: (v) => setState(() => _m.subjectId = v),
        );
      case 2:
        return UploadStepContent(
          key: const ValueKey('step_content'),
          manager: _m,
          onStateChanged: () => setState(() {}),
        );
      case 3:
        return UploadStepReview(
          key: const ValueKey('step_review'),
          manager: _m,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomBar() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isLastStep = _step == 3;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
        border: Border(
            top: BorderSide(
                color: (dark ? DesignTokens.darkBorder : DesignTokens.border)
                    .withValues(alpha: 0.5))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_step > 0) ...[
              OutlinedButton.icon(
                onPressed: _back,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Back'),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: isLastStep
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_m.saving && _m.uploadProgress > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _m.uploadProgress,
                                minHeight: 4,
                                backgroundColor: DesignTokens.border,
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        DesignTokens.primary),
                              ),
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _m.saving
                                ? null
                                : () => _m.submit(context),
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14)),
                            ),
                            icon: _m.saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.cloud_upload_rounded),
                            label: Text(_m.saving
                                ? 'Uploading ${(_m.uploadProgress * 100).toInt()}%'
                                : 'Submit For Review'),
                          ),
                        ),
                      ],
                    )
                  : ElevatedButton(
                      onPressed: _canGoNext ? _next : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Continue',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;

  const _StepIndicator({required this.current, required this.total});

  static const _labels = ['Type', 'Subject', 'Content', 'Review'];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: List.generate(total, (i) {
          final isCompleted = i < current;
          final isCurrent = i == current;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: DesignTokens.durFast,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: isCompleted
                          ? DesignTokens.primary
                          : isCurrent
                              ? DesignTokens.primary.withValues(alpha: 0.5)
                              : (dark
                                  ? DesignTokens.darkBorder
                                  : DesignTokens.border),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _labels[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent
                          ? DesignTokens.primary
                          : DesignTokens.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
