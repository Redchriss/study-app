import 'package:flutter/material.dart';
import 'material_reader_models.dart';
import 'material_reader_services.dart';
import 'reader_chrome.dart';
import 'image_material_reader.dart';
import 'pdf_material_reader.dart';
import 'text_material_reader.dart';
import 'video_material_reader.dart';

class MaterialReaderSelector extends StatelessWidget {
  const MaterialReaderSelector({
    super.key,
    required this.material,
    required this.service,
    required this.onOpenAnnotations,
    required this.onOpenFlashcards,
    required this.onSaveAnnotation,
    required this.onQuickQuiz,
    required this.onAskAi,
  });

  final ReaderMaterialData material;
  final MaterialReaderService service;
  final VoidCallback onOpenAnnotations;
  final VoidCallback onOpenFlashcards;
  final ReaderSelectionCallback onSaveAnnotation;
  final ReaderSelectionCallback onQuickQuiz;
  final ReaderSelectionCallback? onAskAi;

  @override
  Widget build(BuildContext context) {
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
        service: service,
        onOpenAnnotations: onOpenAnnotations,
        onOpenFlashcards: onOpenFlashcards,
        onSaveAnnotation: onSaveAnnotation,
        onQuickQuiz: onQuickQuiz,
        onAskAi: onAskAi,
      );
    }

    if (material.isReadableText) {
      return TextMaterialReader(
        material: material,
        service: service,
        onOpenAnnotations: onOpenAnnotations,
        onOpenFlashcards: onOpenFlashcards,
        onSaveAnnotation: onSaveAnnotation,
        onQuickQuiz: onQuickQuiz,
        onAskAi: onAskAi,
      );
    }

    if (material.isVideo) {
      return VideoMaterialReader(
        material: material,
        service: service,
        onOpenAnnotations: onOpenAnnotations,
        onOpenFlashcards: onOpenFlashcards,
        onSaveAnnotation: onSaveAnnotation,
        onQuickQuiz: onQuickQuiz,
        onAskAi: onAskAi,
      );
    }

    if (material.isImage) {
      return ImageMaterialReader(
        material: material,
        service: service,
        onOpenAnnotations: onOpenAnnotations,
        onOpenFlashcards: onOpenFlashcards,
        onSaveAnnotation: onSaveAnnotation,
        onQuickQuiz: onQuickQuiz,
        onAskAi: onAskAi,
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
