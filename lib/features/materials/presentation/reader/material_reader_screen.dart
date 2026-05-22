import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/services/material_cache_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import 'image_material_reader.dart';
import 'pdf_material_reader.dart';
import 'text_material_reader.dart';
import 'video_material_reader.dart';
import 'material_reader_helpers.dart';
import 'material_reader_models.dart';
import 'material_reader_services.dart';
import 'reader_chrome.dart';
import 'reader_annotation_sheets.dart';
import 'reader_flashcards_sheet.dart';
import 'reader_quiz_sheet.dart';

class MaterialReaderScreen extends StatefulWidget {
  const MaterialReaderScreen({super.key, required this.slug});

  final String slug;

  @override
  State<MaterialReaderScreen> createState() => _MaterialReaderScreenState();
}

class _MaterialReaderScreenState extends State<MaterialReaderScreen> {
  final _service = MaterialReaderService();
  final _cache = MaterialCacheService();
  var _aiActionBusy = false;

  Future<void> _saveAnnotation(
      ReaderStudySelection selection, VoidCallback? refetch) async {
    final draft =
        await showReaderAnnotationComposer(context, selection: selection);
    if (draft == null || !mounted) return;

    final result = await _service.saveAnnotation(
      context: context,
      materialSlug: widget.slug,
      selection: selection,
      noteText: draft.noteText,
      color: draft.color,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success
            ? 'Annotation saved'
            : (result.message ?? 'Could not save annotation.')),
        backgroundColor:
            result.success ? DesignTokens.success : DesignTokens.error,
      ),
    );
    if (result.success) refetch?.call();
  }

  Future<void> _openAnnotations(
      List<ReaderAnnotationData> annotations, VoidCallback? refetch) async {
    await showReaderAnnotationsSheet(
      context,
      annotations: annotations,
      onDelete: (annotation) async {
        final result = await _service.deleteAnnotation(
          context: context,
          annotationId: annotation.id,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.success
                ? 'Annotation removed'
                : (result.message ?? 'Could not delete annotation.')),
            backgroundColor:
                result.success ? DesignTokens.success : DesignTokens.error,
          ),
        );
        if (result.success) {
          Navigator.of(context).pop();
          refetch?.call();
        }
      },
    );
  }

  Future<void> _openFlashcards(
      ReaderMaterialData material, VoidCallback? refetch) async {
    final task = material.taskFor('flashcards');
    await showReaderFlashcardsSheet(
      context,
      flashcards: material.flashcards,
      isGenerating: task?.isActive == true || _aiActionBusy,
      helperText: material.flashcards.isNotEmpty
          ? null
          : task?.statusLabel.isNotEmpty == true
              ? task!.statusLabel
              : 'Generate flashcards from this material and revise them inside study mode.',
      onGenerate: () async {
        if (_aiActionBusy || material.id.isEmpty) return;
        Navigator.of(context).pop();
        setState(() => _aiActionBusy = true);
        final result = await _service.requestAiTask(
          context: context,
          materialId: material.id,
          taskType: 'flashcards',
        );
        if (!mounted) return;
        setState(() => _aiActionBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ??
                result.errors.firstOrNull ??
                'Flashcard request failed.'),
            backgroundColor:
                result.success ? DesignTokens.success : DesignTokens.error,
          ),
        );
        if (result.success) refetch?.call();
      },
    );
  }

  Future<void> _askReaderAi({
    required ReaderMaterialData material,
    required ReaderStudySelection selection,
  }) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Ask AI About This Section',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                for (final item in const [
                  ('explain', 'Explain this section', Icons.lightbulb_outline),
                  (
                    'summary',
                    'Summarize this section',
                    Icons.summarize_outlined
                  ),
                  (
                    'memory',
                    'Create a memory hook',
                    Icons.psychology_alt_outlined
                  ),
                ])
                  ListTile(
                    leading: Icon(item.$3),
                    title: Text(item.$2),
                    onTap: () => Navigator.of(context).pop(item.$1),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (action == null || material.id.isEmpty || !mounted) return;

    final prompt = switch (action) {
      'summary' => 'Summarize this study section into short revision bullets.',
      'memory' =>
        'Create a memorable hook, analogy, or mnemonic from this study section and explain why it works.',
      _ =>
        'Explain this study section clearly in simple language and point out what to remember.',
    };
    final message =
        '$prompt\n\nMaterial: ${material.title}\nAnchor: ${selection.anchorLabel}\n\nCurrent section:\n---\n${selection.selectedText.trim().isEmpty ? 'Use the material context available for this section.' : selection.selectedText.trim()}\n---';

    await _runAiAction<String>(
      action: () => _service.askAi(
          context: context, materialId: material.id, message: message),
      onSuccess: (reply) => showReaderAiReplySheet(
        context,
        title: 'Section AI Reply',
        anchorLabel: selection.anchorLabel,
        reply: reply,
      ),
    );
  }

  Future<void> _runQuickQuiz({
    required ReaderMaterialData material,
    required ReaderStudySelection selection,
  }) async {
    if (material.id.isEmpty) return;
    await _runAiAction<String>(
      action: () => _service.askAi(
        context: context,
        materialId: material.id,
        message: buildQuickQuizPrompt(
          materialTitle: material.title,
          anchorLabel: selection.anchorLabel,
          sectionText: selection.selectedText,
        ),
      ),
      onSuccess: (reply) async {
        final quiz = parseQuickQuizPayload(reply);
        if (quiz == null || !mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'AI could not shape a mini quiz from this section right now.'),
              backgroundColor: DesignTokens.error,
            ),
          );
          return;
        }
        await showReaderQuickQuizSheet(context, quiz: quiz);
      },
    );
  }

  Future<void> _runAiAction<T>({
    required Future<ReaderServiceResult<T>> Function() action,
    required Future<void> Function(T data) onSuccess,
  }) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await action();
    if (!mounted) return;
    Navigator.of(context).pop();

    if (!result.success || result.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ??
              result.errors.firstOrNull ??
              'AI could not help right now.'),
          backgroundColor: DesignTokens.error,
        ),
      );
      return;
    }

    await onSuccess(result.data as T);
  }

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(kMaterial),
        variables: {'slug': widget.slug},
        fetchPolicy: FetchPolicy.cacheAndNetwork,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading && result.data == null) {
          return const ReaderScaffold(
            title: 'Study mode',
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final rawMaterial = result.data?['material'];
        if (result.hasException && rawMaterial is! Map) {
          return FutureBuilder<Map<String, dynamic>?>(
            future: _cache.loadMaterial(widget.slug),
            builder: (context, snapshot) {
              final cached = snapshot.data;
              if (cached == null) {
                return ReaderScaffold(
                  title: 'Study mode',
                  child: ErrorState(
                    message: result.exception?.graphqlErrors.firstOrNull?.message ??
                        'Could not open this material.',
                    onRetry: () => refetch?.call(),
                  ),
                );
              }
              return Stack(
                children: [
                  _buildReaderForMaterial(
                    ReaderMaterialData.fromMap(widget.slug, cached),
                    refetch,
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: DesignTokens.warning.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.offline_bolt_outlined,
                                color: Colors.white, size: 18),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'You are studying from cached material data.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }
        if (rawMaterial is! Map) {
          return const ReaderScaffold(
            title: 'Study mode',
            child: Center(child: Text('Material not found.')),
          );
        }
        _cache.saveMaterial(
            widget.slug, Map<String, dynamic>.from(rawMaterial));
        final material = ReaderMaterialData.fromMap(
            widget.slug, Map<String, dynamic>.from(rawMaterial));
        return _buildReaderForMaterial(material, refetch);
      },
    );
  }

  Widget _buildReaderForMaterial(
      ReaderMaterialData material, VoidCallback? refetch) {
    final theme = Theme.of(context);
    if (material.isPdf) {
      if (material.fileUrl.isEmpty) {
        return ReaderScaffold(
          title: material.title,
          child:
              const Center(child: Text('This PDF is not available right now.')),
        );
      }
      return PdfMaterialReader(
        material: material,
        service: _service,
        onOpenAnnotations: () =>
            _openAnnotations(material.annotations, refetch),
        onOpenFlashcards: () => _openFlashcards(material, refetch),
        onSaveAnnotation: (selection) => _saveAnnotation(selection, refetch),
        onQuickQuiz: (selection) =>
            _runQuickQuiz(material: material, selection: selection),
        onAskAi: material.id.isEmpty
            ? null
            : (selection) =>
                _askReaderAi(material: material, selection: selection),
      );
    }

    if (material.isReadableText) {
      return TextMaterialReader(
        material: material,
        service: _service,
        onOpenAnnotations: () =>
            _openAnnotations(material.annotations, refetch),
        onOpenFlashcards: () => _openFlashcards(material, refetch),
        onSaveAnnotation: (selection) => _saveAnnotation(selection, refetch),
        onQuickQuiz: (selection) =>
            _runQuickQuiz(material: material, selection: selection),
        onAskAi: material.id.isEmpty
            ? null
            : (selection) =>
                _askReaderAi(material: material, selection: selection),
      );
    }

    if (material.isVideo) {
      return VideoMaterialReader(
        material: material,
        service: _service,
        onOpenAnnotations: () =>
            _openAnnotations(material.annotations, refetch),
        onOpenFlashcards: () => _openFlashcards(material, refetch),
        onSaveAnnotation: (selection) => _saveAnnotation(selection, refetch),
        onQuickQuiz: (selection) =>
            _runQuickQuiz(material: material, selection: selection),
        onAskAi: material.id.isEmpty
            ? null
            : (selection) =>
                _askReaderAi(material: material, selection: selection),
      );
    }

    if (material.isImage) {
      return ImageMaterialReader(
        material: material,
        service: _service,
        onOpenAnnotations: () =>
            _openAnnotations(material.annotations, refetch),
        onOpenFlashcards: () => _openFlashcards(material, refetch),
        onSaveAnnotation: (selection) => _saveAnnotation(selection, refetch),
        onQuickQuiz: (selection) =>
            _runQuickQuiz(material: material, selection: selection),
        onAskAi: material.id.isEmpty
            ? null
            : (selection) =>
                _askReaderAi(material: material, selection: selection),
      );
    }

    return ReaderScaffold(
      title: material.title,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Study mode is currently available for PDF, text, video, and image materials.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
