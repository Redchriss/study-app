import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import 'material_reader_helpers.dart';
import 'material_reader_models.dart';
import 'material_reader_services.dart';
import 'reader_chrome.dart';
import 'text_reader_page_widget.dart';

class TextMaterialReader extends StatefulWidget {
  const TextMaterialReader({
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
  State<TextMaterialReader> createState() => _TextMaterialReaderState();
}

class _TextMaterialReaderState extends State<TextMaterialReader> {
  PageController? _pageController;
  int _currentPage = 0;
  int? _selectedParagraphIndex;
  late final Future<int> _savedPageFuture;

  @override
  void initState() {
    super.initState();
    _savedPageFuture = widget.material.progress != null
        ? Future<int>.value(widget.material.progress!.currentUnit)
        : widget.service.loadSavedPage(widget.material.slug, textMode: true);
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (widget.material.textPages.isEmpty) {
      return ReaderScaffold(
        title: widget.material.title,
        child: const Center(child: Text('There is no readable text in this material yet.')),
      );
    }

    return FutureBuilder<int>(
      future: _savedPageFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return ReaderScaffold(
            title: widget.material.title,
            trailing: const ReaderPageBadge(label: 'Opening...'),
            child: const LoadingWidget(),
          );
        }

        final initialPage = snapshot.data!.clamp(0, widget.material.textPages.length - 1).toInt();
        _pageController ??= PageController(initialPage: initialPage);
        _currentPage = _pageController!.hasClients ? _currentPage : initialPage;

        return ReaderScaffold(
          title: widget.material.title,
          trailing: ReaderPageBadge(label: 'Page ${_currentPage + 1} / ${widget.material.textPages.length}'),
          actions: [
            IconButton(icon: const Icon(Icons.sticky_note_2_outlined), onPressed: widget.onOpenAnnotations),
            IconButton(icon: const Icon(Icons.style_outlined), onPressed: widget.onOpenFlashcards),
          ],
          bottomBar: ReaderActionBar(
            onNote: () => widget.onSaveAnnotation(_currentSelection()),
            onQuickQuiz: () => widget.onQuickQuiz(_currentSelection()),
            onFlashcards: widget.onOpenFlashcards,
            onAskAi: widget.onAskAi == null ? null : () => widget.onAskAi!(_currentSelection()),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: dark
                  ? const LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [DesignTokens.darkBackground, DesignTokens.darkSurface],
                    )
                  : const LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Color(0xFFF7F0E1), Color(0xFFEEE4CF)],
                    ),
            ),
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.material.textPages.length,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                  _selectedParagraphIndex = null;
                });
                widget.service.savePage(widget.material.slug, page, textMode: true);
                widget.service.trackProgress(
                  context: context,
                  slug: widget.material.slug,
                  title: widget.material.title,
                  subjectName: widget.material.subjectName,
                  contentType: widget.material.contentType,
                  currentUnit: page,
                  totalUnits: widget.material.textPages.length,
                  lastPositionLabel: 'Page ${page + 1} of ${widget.material.textPages.length}',
                );
              },
              itemBuilder: (context, index) {
                final paragraphs = buildReaderParagraphs(widget.material.textPages[index]);
                return TextReaderPageWidget(
                  material: widget.material,
                  currentPage: index,
                  selectedParagraphIndex: index == _currentPage ? _selectedParagraphIndex : null,
                  paragraphs: paragraphs,
                  onParagraphTap: (paragraphIndex) => setState(() => _selectedParagraphIndex = paragraphIndex),
                );
              },
            ),
          ),
        );
      },
    );
  }

  ReaderStudySelection _currentSelection() {
    final pageText = widget.material.textPages[_currentPage];
    final paragraphs = buildReaderParagraphs(pageText);
    final paragraphIndex = _selectedParagraphIndex;
    if (paragraphIndex != null && paragraphIndex >= 0 && paragraphIndex < paragraphs.length) {
      return ReaderStudySelection(
        unitIndex: _currentPage,
        anchorLabel: 'Page ${_currentPage + 1} · Highlight ${paragraphIndex + 1}',
        selectedText: paragraphs[paragraphIndex],
      );
    }
    return ReaderStudySelection(
      unitIndex: _currentPage,
      anchorLabel: 'Page ${_currentPage + 1}',
      selectedText: pageText,
    );
  }
}
