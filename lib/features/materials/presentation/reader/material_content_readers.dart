import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../../core/theme/design_tokens.dart';
import 'material_reader_helpers.dart';
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
            child: Center(child: CircularProgressIndicator()),
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
            IconButton(
              icon: const Icon(Icons.sticky_note_2_outlined),
              onPressed: widget.onOpenAnnotations,
            ),
            IconButton(
              icon: const Icon(Icons.style_outlined),
              onPressed: widget.onOpenFlashcards,
            ),
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
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final initialPage = snapshot.data!.clamp(0, widget.material.textPages.length - 1).toInt();
        _pageController ??= PageController(initialPage: initialPage);
        _currentPage = _pageController!.hasClients ? _currentPage : initialPage;

        return ReaderScaffold(
          title: widget.material.title,
          trailing: ReaderPageBadge(label: 'Page ${_currentPage + 1} / ${widget.material.textPages.length}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.sticky_note_2_outlined),
              onPressed: widget.onOpenAnnotations,
            ),
            IconButton(
              icon: const Icon(Icons.style_outlined),
              onPressed: widget.onOpenFlashcards,
            ),
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
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        DesignTokens.darkBackground,
                        DesignTokens.darkSurface,
                      ],
                    )
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
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
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                        boxShadow: DesignTokens.shadowLg(false),
                        border: Border.all(color: const Color(0xFFD6C7AB)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (widget.material.subjectName.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: DesignTokens.primary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      widget.material.subjectName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: DesignTokens.primary,
                                      ),
                                    ),
                                  ),
                                const Spacer(),
                                Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: DesignTokens.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: dark
                                    ? DesignTokens.darkSurfaceVariant
                                    : const Color(0xFFF8F2E3),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                'Tap a paragraph to highlight that exact section for notes, quiz, or AI help.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: dark
                                      ? DesignTokens.darkTextSecondary
                                      : DesignTokens.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Expanded(
                              child: ListView.separated(
                                itemCount: paragraphs.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, paragraphIndex) {
                                  final selected = index == _currentPage && _selectedParagraphIndex == paragraphIndex;
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () => setState(() => _selectedParagraphIndex = paragraphIndex),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? (dark
                                                ? DesignTokens.primary.withValues(alpha: 0.18)
                                                : const Color(0xFFF3E6BE))
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: selected
                                              ? (dark
                                                  ? DesignTokens.primaryLight.withValues(alpha: 0.5)
                                                  : const Color(0xFFC28A2C))
                                              : Colors.transparent,
                                        ),
                                      ),
                                      child: Text(
                                        paragraphs[paragraphIndex],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          height: 1.75,
                                          color: DesignTokens.textPrimary,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              index == widget.material.textPages.length - 1 ? 'End of notes' : 'Swipe for next page',
                              style: const TextStyle(
                                fontSize: 12,
                                color: DesignTokens.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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

class VideoMaterialReader extends StatefulWidget {
  const VideoMaterialReader({
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
  State<VideoMaterialReader> createState() => _VideoMaterialReaderState();
}

class _VideoMaterialReaderState extends State<VideoMaterialReader> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final videoId = resolveYoutubeVideoId(widget.material.youtubeEmbedUrl);
    if (videoId != null && videoId.isNotEmpty) {
      _controller = YoutubePlayerController(
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          strictRelatedVideos: true,
        ),
      )..loadVideoById(videoId: videoId);
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
            lastPositionLabel: 'Continue watching',
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return ReaderScaffold(
        title: widget.material.title,
        child: const Center(child: Text('This video could not be opened in study mode.')),
      );
    }

    return ReaderScaffold(
      title: widget.material.title,
      trailing: const ReaderPageBadge(label: 'Video lesson'),
      actions: [
        IconButton(
          icon: const Icon(Icons.sticky_note_2_outlined),
          onPressed: widget.onOpenAnnotations,
        ),
        IconButton(
          icon: const Icon(Icons.style_outlined),
          onPressed: widget.onOpenFlashcards,
        ),
      ],
      bottomBar: ReaderActionBar(
        onNote: () => widget.onSaveAnnotation(_selection()),
        onQuickQuiz: () => widget.onQuickQuiz(_selection()),
        onFlashcards: widget.onOpenFlashcards,
        onAskAi: widget.onAskAi == null ? null : () => widget.onAskAi!(_selection()),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.material.subjectName.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: ReaderTag(label: widget.material.subjectName),
            ),
            const SizedBox(height: 12),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: YoutubePlayer(
              controller: _controller!,
              aspectRatio: 16 / 9,
            ),
          ),
          const SizedBox(height: 16),
          const ReaderTip(
            text: 'Watch inside the app, then use quick quiz, flashcards, or AI help without leaving study mode.',
          ),
        ],
      ),
    );
  }

  ReaderStudySelection _selection() {
    final pages = widget.material.textPages;
    return ReaderStudySelection(
      unitIndex: 0,
      anchorLabel: 'Video lesson',
      selectedText: pages.isEmpty ? widget.material.contentText : pages.first,
    );
  }
}

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
          onPressed: widget.onOpenAnnotations,
        ),
        IconButton(
          icon: const Icon(Icons.style_outlined),
          onPressed: widget.onOpenFlashcards,
        ),
      ],
      bottomBar: ReaderActionBar(
        onNote: () => widget.onSaveAnnotation(_selection()),
        onQuickQuiz: () => widget.onQuickQuiz(_selection()),
        onFlashcards: widget.onOpenFlashcards,
        onAskAi: widget.onAskAi == null ? null : () => widget.onAskAi!(_selection()),
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
                  child: ReaderTag(label: widget.material.subjectName),
                ),
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
                        child: Text(
                          'This image could not be loaded right now.',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: ReaderTip(
                text: 'Pinch to zoom, then save a highlight or quiz yourself on the diagram without leaving the app.',
              ),
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
