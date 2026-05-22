import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/services/material_cache_service.dart';
import '../../../../core/theme/design_tokens.dart';
import 'material_reader_error_handler.dart';
import 'material_reader_helpers.dart';
import 'material_reader_models.dart';
import 'material_reader_selector.dart';
import 'material_reader_services.dart';
import 'reader_ai_action_sheet.dart';
import 'reader_annotation_sheets.dart';
import 'reader_flashcards_sheet.dart';
import 'reader_loading.dart';
import 'reader_not_found.dart';
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

  void _showResultSnackBar(ReaderServiceResult result, String onSuccess, String onFail) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success ? onSuccess : (result.message ?? onFail)),
        backgroundColor: result.success ? DesignTokens.success : DesignTokens.error,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DesignTokens.error,
      ),
    );
  }

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
    _showResultSnackBar(result, 'Annotation saved', 'Could not save annotation.');
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
        _showResultSnackBar(result, 'Annotation removed', 'Could not delete annotation.');
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
        _showResultSnackBar(result, 'Flashcards requested', result.message ?? result.errors.firstOrNull ?? 'Flashcard request failed.');
        if (result.success) refetch?.call();
      },
    );
  }

  Future<void> _askReaderAi({
    required ReaderMaterialData material,
    required ReaderStudySelection selection,
  }) async {
    final action = await showReaderAiActionSheet(context);
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
          _showErrorSnackBar('AI could not shape a mini quiz from this section right now.');
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
      _showErrorSnackBar(result.message ?? result.errors.firstOrNull ?? 'AI could not help right now.');
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
          return const ReaderLoading();
        }
        final rawMaterial = result.data?['material'];
        if (result.hasException && rawMaterial is! Map) {
          return MaterialReaderErrorHandler(
            slug: widget.slug,
            errorMessage: result.exception?.graphqlErrors.firstOrNull?.message ??
                'Could not open this material.',
            onRetry: () => refetch?.call(),
            cache: _cache,
            onCachedData: (material) =>
                _buildReaderForMaterial(material, refetch),
          );
        }
        if (rawMaterial is! Map) {
          return const ReaderNotFound();
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
    return MaterialReaderSelector(
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
}
