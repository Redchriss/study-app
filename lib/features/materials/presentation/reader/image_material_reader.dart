import 'package:flutter/material.dart';

import 'material_reader_models.dart';
import 'material_reader_services.dart';
import 'reader_chrome.dart';

class ImageMaterialReader extends StatefulWidget {
  const ImageMaterialReader({
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
  State<ImageMaterialReader> createState() => _ImageMaterialReaderState();
}

class _ImageMaterialReaderState extends State<ImageMaterialReader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.service.trackProgress(
          context: context,
          slug: widget.material.slug,
          title: widget.material.title,
          subjectName: widget.material.subjectName,
          contentType: widget.material.contentType,
          currentUnit: 0,
          totalUnits: 1,
          lastPositionLabel: 'Continue studying',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ReaderScaffold(
      title: widget.material.title,
      trailing: const ReaderPageBadge(label: 'Image material'),
      actions: [
        IconButton(
            icon: const Icon(Icons.sticky_note_2_outlined),
            onPressed: widget.onOpenAnnotations),
        IconButton(
            icon: const Icon(Icons.style_outlined),
            onPressed: widget.onOpenFlashcards),
      ],
      bottomBar: ReaderActionBar(
        onNote: () => widget.onSaveAnnotation(_selection()),
        onQuickQuiz: () => widget.onQuickQuiz(_selection()),
        onFlashcards: widget.onOpenFlashcards,
        onAskAi:
            widget.onAskAi == null ? null : () => widget.onAskAi!(_selection()),
      ),
      child: Container(
        color: const Color(0xFF101114),
        child: Column(
          children: [
            if (widget.material.subjectName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: ReaderTag(label: widget.material.subjectName)),
              ),
            Expanded(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Center(
                  child: Image.network(
                    widget.material.fileUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('This image could not be loaded right now.',
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center),
                      );
                    },
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: ReaderTip(
                  text:
                      'Pinch to zoom, then save a highlight or quiz yourself on the diagram without leaving the app.'),
            ),
          ],
        ),
      ),
    );
  }

  ReaderStudySelection _selection() {
    final pages = widget.material.textPages;
    return ReaderStudySelection(
      unitIndex: 0,
      anchorLabel: 'Image material',
      selectedText: pages.isEmpty ? widget.material.contentText : pages.first,
    );
  }
}
