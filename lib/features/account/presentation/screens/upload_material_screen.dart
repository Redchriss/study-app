import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/services/material_upload_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/upload_success_sheet.dart';

class UploadMaterialScreen extends ConsumerStatefulWidget {
  const UploadMaterialScreen({super.key});

  @override
  ConsumerState<UploadMaterialScreen> createState() => _UploadMaterialScreenState();
}

class _UploadMaterialScreenState extends ConsumerState<UploadMaterialScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _textCtrl = TextEditingController();
  final _youtubeCtrl = TextEditingController();
  final _uploadService = MaterialUploadService();

  String _contentType = 'pdf';
  String? _subjectId;
  bool _saving = false;
  bool _loadingSubjects = true;
  String? _subjectLoadError;
  PlatformFile? _selectedFile;
  List? _subjects;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final auth = ref.read(authProvider);
    final educationLevel = auth.user?['profile']?['educationLevel']?.toString();

    if (educationLevel == null || educationLevel.isEmpty) {
      setState(() {
        _loadingSubjects = false;
        _subjectLoadError = 'Complete your profile education level before uploading materials.';
      });
      return;
    }

    setState(() {
      _loadingSubjects = true;
      _subjectLoadError = null;
    });
    final client = ref.read(graphqlClientProvider);
    final result = await client.query(
      QueryOptions(
        document: gql(kSubjects),
        variables: {'educationLevel': educationLevel},
        fetchPolicy: FetchPolicy.cacheFirst,
      ),
    );
    if (!mounted) return;
    if (result.hasException) {
      setState(() {
        _loadingSubjects = false;
        _subjectLoadError = result.exception?.graphqlErrors.firstOrNull?.message ?? 'Could not load subjects.';
      });
      return;
    }
    setState(() {
      _subjects = (result.data?['subjects'] as List?) ?? [];
      _loadingSubjects = false;
    });
  }

  bool get _requiresFile => _contentType == 'pdf' || _contentType == 'image';

  bool get _supportsOptionalFile => _contentType == 'text';

  String get _levelLabel {
    switch (ref.read(authProvider).user?['profile']?['educationLevel']?.toString() ?? 'secondary') {
      case 'primary': return 'Primary';
      case 'tertiary': return 'Tertiary / University';
      default: return 'Secondary';
    }
  }

  String get _titlePlaceholder {
    final level = ref.read(authProvider).user?['profile']?['educationLevel']?.toString() ?? 'secondary';
    switch (_contentType) {
      case 'pdf':
        if (level == 'primary') return 'e.g. Standard 7 Maths – Fractions';
        if (level == 'tertiary') return 'e.g. UNIMA Physics 201 – Thermodynamics Notes';
        return 'e.g. Form 3 Biology – Respiration';
      case 'image':
        if (level == 'primary') return 'e.g. Diagram – Water Cycle';
        if (level == 'tertiary') return 'e.g. Anatomy Diagram – Digestive System';
        return 'e.g. MSCE Geography – Rainfall Map';
      case 'video':
        if (level == 'primary') return 'e.g. English Lesson – Parts of Speech';
        if (level == 'tertiary') return 'e.g. Organic Chemistry – Alkene Reactions';
        return 'e.g. MSCE Mathematics – Differentiation';
      case 'text':
        if (level == 'primary') return 'e.g. Science Summary – Living Things';
        if (level == 'tertiary') return 'e.g. Law Notes – Constitutional Law';
        return 'e.g. History Notes – Colonial Malawi';
      default:
        return 'e.g. Form 3 Biology Notes – Respiration';
    }
  }

  String get _descPlaceholder {
    final level = ref.read(authProvider).user?['profile']?['educationLevel']?.toString() ?? 'secondary';
    if (level == 'primary') return 'What topic does this cover? What standard is it for?';
    if (level == 'tertiary') return 'What course, year, and topics are covered in this material?';
    return 'What form and subject is this for? What topics does it cover?';
  }

  String get _primaryHint {
    switch (_contentType) {
      case 'pdf':
        return 'Upload revision booklets, topic handouts, or scanned notes that students can read in-app.';
      case 'image':
        return 'Upload diagrams, worked examples, maps, or annotated pages students can zoom into.';
      case 'video':
        return 'Use a YouTube lesson so students can watch in-app and the AI can reuse transcripts when available.';
      case 'text':
        return 'Paste notes directly or attach a readable file if you already have one.';
      default:
        return '';
    }
  }

  String get _fileButtonLabel {
    switch (_contentType) {
      case 'pdf':
        return 'Choose PDF';
      case 'image':
        return 'Choose Image';
      case 'text':
        return 'Attach File';
      default:
        return 'Choose File';
    }
  }

  List<String> _allowedExtensions() {
    switch (_contentType) {
      case 'pdf':
        return const ['pdf'];
      case 'image':
        return const ['png', 'jpg', 'jpeg', 'gif', 'webp'];
      case 'text':
        return const ['pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx'];
      default:
        return const [];
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: _allowedExtensions(),
    );
    if (!mounted || result == null || result.files.isEmpty) return;
    setState(() => _selectedFile = result.files.single);
  }

  void _changeType(String nextType) {
    if (_contentType == nextType) return;
    setState(() {
      _contentType = nextType;
      _selectedFile = null;
      _textCtrl.clear();
      _youtubeCtrl.clear();
    });
  }

  List<String> _validateForm() {
    final errors = <String>[];
    if (_titleCtrl.text.trim().isEmpty) errors.add('Add a clear title.');
    if (_subjectId == null) errors.add('Pick a subject.');
    if (_requiresFile && _selectedFile == null) errors.add('Choose a file for this material.');
    if (_contentType == 'video' && _youtubeCtrl.text.trim().isEmpty) {
      errors.add('Paste a YouTube link for the lesson.');
    }
    if (_contentType == 'text' &&
        _textCtrl.text.trim().isEmpty &&
        _selectedFile == null) {
      errors.add('Paste notes or attach a file for this text material.');
    }
    return errors;
  }

  Future<void> _submit() async {
    final errors = _validateForm();
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errors.first), backgroundColor: DesignTokens.error),
      );
      return;
    }

    setState(() => _saving = true);
    final result = await _uploadService.upload(
      title: _titleCtrl.text.trim(),
      subjectId: _subjectId!,
      contentType: _contentType,
      description: _descCtrl.text.trim(),
      contentText: _textCtrl.text.trim(),
      youtubeUrl: _youtubeCtrl.text.trim(),
      file: _selectedFile,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errors.isNotEmpty ? result.errors.first : (result.message ?? 'Upload failed')),
          backgroundColor: DesignTokens.error,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message ?? 'Material submitted for review'),
        backgroundColor: DesignTokens.success,
      ),
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => UploadSuccessSheet(result: result),
    );
    if (mounted) {
      _titleCtrl.clear();
      _descCtrl.clear();
      _textCtrl.clear();
      _youtubeCtrl.clear();
      setState(() => _selectedFile = null);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _textCtrl.dispose();
    _youtubeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const types = [
      ('pdf', 'PDF', Icons.picture_as_pdf_rounded, Color(0xFFC8583D)),
      ('text', 'Notes', Icons.menu_book_rounded, Color(0xFF1F6A52)),
      ('image', 'Image', Icons.image_rounded, Color(0xFF7A4D9E)),
      ('video', 'Video', Icons.ondemand_video_rounded, Color(0xFF005B8F)),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Upload Material', style: theme.textTheme.titleLarge)),
      body: RefreshIndicator(
        onRefresh: _loadSubjects,
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.spMd),
          children: [
            Container(
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
                  Text(
                    'Build Better Study Sessions',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: DesignTokens.spXs),
                  Text(
                    'Upload focused materials students can read, watch, or inspect inside the app without leaving their study flow.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: DesignTokens.textSecondary),
                  ),
                  const SizedBox(height: DesignTokens.spMd),
                  Row(
                    children: [
                      const _UploadPill(label: 'AI-ready first'),
                      SizedBox(width: DesignTokens.spSm),
                      const _UploadPill(label: 'Mobile-friendly'),
                      SizedBox(width: DesignTokens.spSm),
                      _UploadPill(label: _levelLabel),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spLg),
            const SectionHeader(title: 'Material Type'),
            const SizedBox(height: DesignTokens.spSm),
            Wrap(
              spacing: DesignTokens.spSm,
              runSpacing: DesignTokens.spSm,
              children: [
                for (final type in types)
                  _TypeCard(
                    selected: _contentType == type.$1,
                    label: type.$2,
                    icon: type.$3,
                    color: type.$4,
                    onTap: () => _changeType(type.$1),
                  ),
              ],
            ),
            const SizedBox(height: DesignTokens.spMd),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What students get',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: DesignTokens.spXs),
                  Text(
                    _primaryHint,
                    style: theme.textTheme.bodyMedium?.copyWith(color: DesignTokens.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spLg),
            GlassCard(
              child: Column(
                children: [
                  TextField(
                    controller: _titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      hintText: _titlePlaceholder,
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: DesignTokens.spMd),
                  if (_loadingSubjects)
                    const ShimmerBox(height: 56, radius: DesignTokens.radiusMd)
                  else if (_subjectLoadError != null)
                    ErrorState(message: _subjectLoadError!, onRetry: _loadSubjects)
                  else
                    DropdownButtonFormField<String>(
                      key: ValueKey('subject_${_subjects?.length}_$_subjectId'),
                      initialValue: _subjectId,
                      decoration: const InputDecoration(labelText: 'Subject'),
                      items: (_subjects ?? [])
                          .map((s) => DropdownMenuItem<String>(
                                value: s['id']?.toString(),
                                child: Text(s['name']?.toString() ?? ''),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _subjectId = value),
                    ),
                  const SizedBox(height: DesignTokens.spMd),
                  TextField(
                    controller: _descCtrl,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: _descPlaceholder,
                    ),
                    maxLines: 3,
                    textInputAction: TextInputAction.next,
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spLg),
            if (_contentType == 'video') ...[
              GlassCard(
                child: TextField(
                  controller: _youtubeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'YouTube URL',
                    hintText: 'https://www.youtube.com/watch?v=...',
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spLg),
            ],
            if (_contentType == 'text') ...[
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paste notes',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: DesignTokens.spXs),
                    Text(
                      'Best for summaries, flashcards, and quizzes. You can still attach a file below.',
                      style: theme.textTheme.bodySmall?.copyWith(color: DesignTokens.textSecondary),
                    ),
                    const SizedBox(height: DesignTokens.spMd),
                    TextField(
                      controller: _textCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Study content',
                        hintText: 'Paste notes, transcript text, or clean OCR text here.',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DesignTokens.spLg),
            ],
            if (_requiresFile || _supportsOptionalFile) ...[
              AnimatedPress(
                onTap: _pickFile,
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: DesignTokens.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.upload_file_rounded, color: DesignTokens.primary),
                          ),
                          const SizedBox(width: DesignTokens.spMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _fileButtonLabel,
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _requiresFile
                                      ? 'Required for this material type.'
                                      : 'Optional, but useful when you already have a file version.',
                                  style: theme.textTheme.bodySmall?.copyWith(color: DesignTokens.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: DesignTokens.textTertiary),
                        ],
                      ),
                      if (_selectedFile != null) ...[
                        const SizedBox(height: DesignTokens.spMd),
                        _FilePreviewCard(file: _selectedFile!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spLg),
            ],
            Container(
              padding: const EdgeInsets.all(DesignTokens.spMd),
              decoration: BoxDecoration(
                color: const Color(0xFF102A43),
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upload checklist',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: DesignTokens.spXs),
                  const Text(
                    'Keep titles specific, match the right subject, and prefer readable notes over blurry scans when possible.',
                    style: TextStyle(color: Colors.white70, height: 1.5),
                  ),
                  if (_contentType == 'video') ...[
                    const SizedBox(height: DesignTokens.spXs),
                    const Text(
                      'Video lessons work best when the linked YouTube video has captions or a transcript.',
                      style: TextStyle(color: Colors.white70, height: 1.5),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spLg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(_saving ? 'Uploading...' : 'Submit For Review'),
              ),
            ),
            const SizedBox(height: DesignTokens.spXl),
          ],
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.selected,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedPress(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 144,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? color : DesignTokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _UploadPill extends StatelessWidget {
  const _UploadPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: DesignTokens.textPrimary,
        ),
      ),
    );
  }
}

class _FilePreviewCard extends StatelessWidget {
  const _FilePreviewCard({required this.file});

  final PlatformFile file;

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: DesignTokens.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.insert_drive_file_rounded, color: DesignTokens.primary),
          ),
          const SizedBox(width: DesignTokens.spMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatSize(file.size),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DesignTokens.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
