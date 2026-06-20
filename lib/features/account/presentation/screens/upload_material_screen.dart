import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'upload_form_fields.dart';
import 'upload_material_labels.dart';
import 'upload_material_manager.dart';
import 'upload_material_widgets.dart';
import '../../../materials/presentation/widgets/youtube_search_picker.dart';

class UploadMaterialScreen extends ConsumerStatefulWidget {
  const UploadMaterialScreen({super.key});
  @override
  ConsumerState<UploadMaterialScreen> createState() =>
      _UploadMaterialScreenState();
}

class _UploadMaterialScreenState extends ConsumerState<UploadMaterialScreen>
    with SingleTickerProviderStateMixin {
  final _m = UploadMaterialManager();
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _m.attach(
      ref: ref,
      setState: (fn) => setState(fn),
      isMounted: () => mounted,
    );
    _m.init();
    _entrance = AnimationController(
      vsync: this,
      duration: DesignTokens.durSlow,
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _m.dispose();
    super.dispose();
  }

  /// A staggered fade + slide-up so the form assembles itself on open.
  Widget _entranceItem(int index, Widget child) {
    final start = (index * 0.06).clamp(0.0, 0.6);
    final animation = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, (1 - animation.value) * 18),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    _m.updateEducationLevel(
        auth.user?['profile']?['educationLevel']?.toString());
    const types = [
      ('pdf', 'PDF', Icons.picture_as_pdf_rounded, Color(0xFFC8583D)),
      ('text', 'Notes', Icons.menu_book_rounded, Color(0xFF1F6A52)),
      ('image', 'Image', Icons.image_rounded, Color(0xFF7A4D9E)),
      ('video', 'Video', Icons.ondemand_video_rounded, Color(0xFF005B8F)),
    ];

    return Scaffold(
      appBar: AppBar(
          title: Text('Upload Material', style: theme.textTheme.titleLarge)),
      body: RefreshIndicator(
        onRefresh: _m.loadSubjects,
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.spMd),
          children: [
            _entranceItem(0, _buildHeader()),
            const SizedBox(height: DesignTokens.spLg),
            _entranceItem(1, _buildAiFillButton()),
            const SizedBox(height: DesignTokens.spLg),
            _entranceItem(2, const SectionHeader(title: 'Material Type')),
            const SizedBox(height: DesignTokens.spSm),
            _entranceItem(
              3,
              Wrap(
                spacing: DesignTokens.spSm,
                runSpacing: DesignTokens.spSm,
                children: [
                  for (final type in types)
                    TypeCard(
                      selected: _m.contentType == type.$1,
                      label: type.$2,
                      icon: type.$3,
                      color: type.$4,
                      onTap: () => _m.changeType(type.$1),
                    ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spMd),
            _entranceItem(4, _buildHintCard()),
            const SizedBox(height: DesignTokens.spLg),
            _entranceItem(
              5,
              UploadFormFields(
                manager: _m,
                onSubjectChanged: (value) =>
                    setState(() => _m.subjectId = value),
              ),
            ),
            const SizedBox(height: DesignTokens.spLg),
            if (_m.contentType == 'video') ...[
              const Text('Search YouTube',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: DesignTokens.spSm),
              YouTubeSearchPicker(
                onSelected: (url) {
                  _m.youtubeCtrl.text = url;
                  setState(() {});
                },
              ),
              const SizedBox(height: DesignTokens.spLg),
              GlassCard(
                child: TextField(
                  controller: _m.youtubeCtrl,
                  decoration: InputDecoration(
                    labelText: 'Or paste YouTube URL',
                    hintText: 'https://www.youtube.com/watch?v=...',
                    suffixIcon: _m.youtubeCtrl.text.isNotEmpty
                        ? Icon(
                            _isValidYoutubeUrl(_m.youtubeCtrl.text)
                                ? Icons.check_circle_rounded
                                : Icons.error_outline_rounded,
                            color: _isValidYoutubeUrl(_m.youtubeCtrl.text)
                                ? DesignTokens.success
                                : DesignTokens.error,
                            size: 20,
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: DesignTokens.spLg),
            ],
            if (_m.contentType == 'text') ...[
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Paste notes',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: DesignTokens.spXs),
                    Text(
                      'Best for summaries, flashcards, and quizzes. You can still attach a file below.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: DesignTokens.textSecondary),
                    ),
                    const SizedBox(height: DesignTokens.spMd),
                    TextField(
                      controller: _m.textCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Study content',
                        hintText:
                            'Paste notes, transcript text, or clean OCR text here.',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DesignTokens.spLg),
            ],
            if (_m.requiresFile || _m.supportsOptionalFile) ...[
              FilePickerCard(
                fileButtonLabel:
                    UploadMaterialLabels.fileButtonLabel(_m.contentType),
                requiresFile: _m.requiresFile,
                selectedFile: _m.selectedFile,
                onPick: _m.pickFile,
              ),
              const SizedBox(height: DesignTokens.spLg),
            ],
            UploadChecklist(isVideo: _m.contentType == 'video'),
            const SizedBox(height: DesignTokens.spLg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _m.saving ? null : () => _m.submit(context),
                icon: _m.saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(_m.saving ? 'Uploading...' : 'Submit For Review'),
              ),
            ),
            const SizedBox(height: DesignTokens.spXl),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spLg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF1E5C8), Color(0xFFE1F0EE)],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Build Better Study Sessions',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: DesignTokens.spXs),
          Text(
            'Upload focused materials students can read, watch, or inspect inside the app without leaving their study flow.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: DesignTokens.textSecondary),
          ),
          const SizedBox(height: DesignTokens.spMd),
          Row(
            children: [
              const UploadPill(label: 'AI-ready first'),
              const SizedBox(width: DesignTokens.spSm),
              const UploadPill(label: 'Mobile-friendly'),
              const SizedBox(width: DesignTokens.spSm),
              UploadPill(
                  label: UploadMaterialLabels.levelLabel(_m.educationLevel)),
            ],
          ),
        ],
      ),
    );
  }

  bool _isValidYoutubeUrl(String url) {
    final regex = RegExp(
      r'^(https?://)?(www\.)?(youtube\.com|youtu\.be)/',
    );
    return regex.hasMatch(url.trim());
  }

  /// Opt-in, cost-aware AI auto-fill. Reads pasted notes / picked file and
  /// suggests title, subject, and type — editable, never blocking the form.
  Widget _buildAiFillButton() {
    final theme = Theme.of(context);
    final ready = _m.canSuggestMetadata;
    return Material(
      key: const Key('ai_fill_button'),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        onTap: _m.suggesting ? null : () => _m.suggestMetadata(context),
        child: Ink(
          padding: const EdgeInsets.all(DesignTokens.spMd),
          decoration: BoxDecoration(
            gradient: DesignTokens.brandGradient,
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
            boxShadow: DesignTokens.shadowMd(false),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: _m.suggesting
                    ? const Padding(
                        padding: EdgeInsets.all(11),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white),
              ),
              const SizedBox(width: DesignTokens.spMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _m.suggesting ? 'Reading your material…' : 'Fill with AI',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ready
                          ? 'Suggest title, subject & type · 1 credit'
                          : 'Add notes or pick a file, then tap to auto-fill',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              if (!_m.suggesting)
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHintCard() {
    final theme = Theme.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What students get',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: DesignTokens.spXs),
          Text(UploadMaterialLabels.primaryHint(_m.contentType),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: DesignTokens.textSecondary)),
        ],
      ),
    );
  }
}
