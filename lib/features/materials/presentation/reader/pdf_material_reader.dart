import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import 'material_reader_models.dart';
import 'material_reader_services.dart';
import 'reader_chrome.dart';

class PdfMaterialReader extends StatefulWidget {
  const PdfMaterialReader({
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
  State<PdfMaterialReader> createState() => _PdfMaterialReaderState();
}

class _PdfMaterialReaderState extends State<PdfMaterialReader> {
  int _currentPage = 0;
  int _pageCount = 0;
  late final Future<(String?, int)> _documentFuture;

  @override
  void initState() {
    super.initState();
    _documentFuture = () async {
      final filePath = await widget.service.cachePdf(widget.material.fileUrl, widget.material.slug);
      final savedPage = widget.material.progress?.currentUnit ?? await widget.service.loadSavedPage(widget.material.slug);
      return (filePath, savedPage);
    }();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(String?, int)>(
      future: _documentFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ReaderScaffold(
            title: 'Study mode',
            trailing: ReaderPageBadge(label: 'Opening...'),
            child: LoadingWidget(),
          );
        }

        final filePath = snapshot.data!.$1;
        final savedPage = snapshot.data!.$2;
        if (filePath == null) {
          return ReaderScaffold(
            title: widget.material.title,
            child: const Center(child: Text('Could not prepare this PDF for reading.')),
          );
        }

        return ReaderScaffold(
          title: widget.material.title,
          trailing: ReaderPageBadge(
            label: _pageCount == 0 ? 'Loading...' : 'Page ${_currentPage + 1} / $_pageCount',
          ),
          actions: [
            IconButton(icon: const Icon(Icons.sticky_note_2_outlined), onPressed: widget.onOpenAnnotations),
            IconButton(icon: const Icon(Icons.style_outlined), onPressed: widget.onOpenFlashcards),
          ],
          bottomBar: ReaderActionBar(
            onNote: () => widget.onSaveAnnotation(_selectionForCurrentPage()),
            onQuickQuiz: () => widget.onQuickQuiz(_selectionForCurrentPage()),
            onFlashcards: widget.onOpenFlashcards,
            onAskAi: widget.onAskAi == null ? null : () => widget.onAskAi!(_selectionForCurrentPage()),
          ),
          child: Container(
            color: Colors.black,
            child: PDFView(
              filePath: filePath,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageSnap: true,
              defaultPage: savedPage,
              fitPolicy: FitPolicy.BOTH,
              onRender: (pages) {
                if (!mounted) return;
                setState(() {
                  _pageCount = pages ?? 0;
                  _currentPage = savedPage.clamp(0, (pages ?? 1) - 1).toInt();
                });
              },
              onPageChanged: (page, total) {
                final nextPage = page ?? 0;
                if (!mounted) return;
                setState(() {
                  _currentPage = nextPage;
                  _pageCount = total ?? _pageCount;
                });
                widget.service.savePage(widget.material.slug, nextPage);
                widget.service.trackProgress(
                  context: context,
                  slug: widget.material.slug,
                  title: widget.material.title,
                  subjectName: widget.material.subjectName,
                  contentType: widget.material.contentType,
                  currentUnit: nextPage,
                  totalUnits: total ?? _pageCount,
                  lastPositionLabel: 'Page ${nextPage + 1} of ${total ?? _pageCount}',
                );
              },
              onError: (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not open PDF: $error'), backgroundColor: DesignTokens.error),
                );
              },
            ),
          ),
        );
      },
    );
  }

  ReaderStudySelection _selectionForCurrentPage() {
    final sectionPages = widget.material.textPages;
    return ReaderStudySelection(
      unitIndex: _currentPage,
      anchorLabel: 'Page ${_currentPage + 1}',
      selectedText: sectionPages.length > _currentPage ? sectionPages[_currentPage] : '',
    );
  }
}
