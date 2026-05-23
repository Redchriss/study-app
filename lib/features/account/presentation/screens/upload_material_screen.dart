import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'upload_form_fields.dart';
import 'upload_material_manager.dart';
import 'upload_material_widgets.dart';

class UploadMaterialScreen extends ConsumerStatefulWidget {
  const UploadMaterialScreen({super.key});
  @override
  ConsumerState<UploadMaterialScreen> createState() =>
      _UploadMaterialScreenState();
}

class _UploadMaterialScreenState extends ConsumerState<UploadMaterialScreen> {
  final _m = UploadMaterialManager();

  @override
  void initState() {
    super.initState();
    _m.attach(
      ref: ref,
      setState: (fn) => setState(fn),
      isMounted: () => mounted,
    );
    _m.init();
  }

  @override
  void dispose() {
    _m.dispose();
    super.dispose();
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
            _buildHeader(),
            const SizedBox(height: DesignTokens.spLg),
            const SectionHeader(title: 'Material Type'),
            const SizedBox(height: DesignTokens.spSm),
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
            const SizedBox(height: DesignTokens.spMd),
            _buildHintCard(),
            const SizedBox(height: DesignTokens.spLg),
            UploadFormFields(
              manager: _m,
              onSubjectChanged: (value) => setState(() => _m.subjectId = value),
            ),
            const SizedBox(height: DesignTokens.spLg),
            if (_m.contentType == 'video') ...[
              GlassCard(
                child: TextField(
                  controller: _m.youtubeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'YouTube URL',
                    hintText: 'https://www.youtube.com/watch?v=...',
                  ),
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
                fileButtonLabel: _m.fileButtonLabel(),
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
              UploadPill(label: _m.levelLabel(context)),
            ],
          ),
        ],
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
          Text(_m.primaryHint(),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: DesignTokens.textSecondary)),
        ],
      ),
    );
  }
}
