import 'dart:io';

import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/services/study_progress_store.dart';
import '../../../../core/theme/design_tokens.dart';

class MaterialReaderScreen extends StatefulWidget {
  const MaterialReaderScreen({super.key, required this.slug});

  final String slug;

  @override
  State<MaterialReaderScreen> createState() => _MaterialReaderScreenState();
}

class _MaterialReaderScreenState extends State<MaterialReaderScreen> {
  static const _pageProgressPrefix = 'reader_page_';
  static const _textProgressPrefix = 'reader_text_page_';
  final _progressStore = StudyProgressStore();

  Future<String?> _cachePdf(String url, String slug) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/reader_$slug.pdf');
    if (await file.exists() && await file.length() > 0) {
      return file.path;
    }
    final response = await http.get(uri);
    if (response.statusCode != 200) return null;
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file.path;
  }

  Future<int> _loadSavedPage(String slug, {bool textMode = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = textMode ? '$_textProgressPrefix$slug' : '$_pageProgressPrefix$slug';
    return prefs.getInt(key) ?? 0;
  }

  Future<void> _savePage(String slug, int page, {bool textMode = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = textMode ? '$_textProgressPrefix$slug' : '$_pageProgressPrefix$slug';
    await prefs.setInt(key, page);
  }

  bool _isPdfMaterial(Map<String, dynamic> material) {
    final contentType = (material['contentType'] as String? ?? '').toLowerCase();
    final fileUrl = material['fileUrl'] as String? ?? '';
    return contentType == 'pdf' || fileUrl.toLowerCase().endsWith('.pdf');
  }

  bool _isReadableText(Map<String, dynamic> material) {
    final contentType = (material['contentType'] as String? ?? '').toLowerCase();
    final contentText = (material['contentText'] as String? ?? '').trim();
    return contentType == 'text' && contentText.isNotEmpty;
  }

  bool _isVideoMaterial(Map<String, dynamic> material) {
    final contentType = (material['contentType'] as String? ?? '').toLowerCase();
    final youtubeUrl = material['youtubeEmbedUrl'] as String? ?? '';
    return contentType == 'video' && youtubeUrl.isNotEmpty;
  }

  bool _isImageMaterial(Map<String, dynamic> material) {
    final contentType = (material['contentType'] as String? ?? '').toLowerCase();
    final fileUrl = material['fileUrl'] as String? ?? '';
    return contentType == 'image' && fileUrl.isNotEmpty;
  }

  List<String> _buildTextPages(String text) {
    final cleaned = text
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    if (cleaned.isEmpty) return const <String>[];

    final paragraphs = cleaned.split('\n\n');
    final pages = <String>[];
    final buffer = StringBuffer();
    var currentLength = 0;

    for (final paragraph in paragraphs) {
      final block = paragraph.trim();
      if (block.isEmpty) continue;
      final nextLength = currentLength + block.length;
      if (nextLength > 1300 && currentLength > 0) {
        pages.add(buffer.toString().trim());
        buffer.clear();
        currentLength = 0;
      }
      if (buffer.isNotEmpty) {
        buffer.writeln();
        buffer.writeln();
        currentLength += 2;
      }
      buffer.write(block);
      currentLength += block.length;
    }

    if (buffer.isNotEmpty) {
      pages.add(buffer.toString().trim());
    }
    return pages;
  }

  String? _videoIdFromUrl(String url) {
    final direct = YoutubePlayerController.convertUrlToId(url);
    if (direct != null && direct.isNotEmpty) return direct;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final segments = uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
    if (segments.isEmpty) return null;
    return segments.last;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Query(
      options: QueryOptions(
        document: gql(kMaterial),
        variables: {'slug': widget.slug},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return const _ReaderScaffold(
            title: 'Study mode',
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (result.hasException) {
          return _ReaderScaffold(
            title: 'Study mode',
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  result.exception?.graphqlErrors.firstOrNull?.message ?? 'Could not open this material.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final material = result.data?['material'] as Map<String, dynamic>?;
        if (material == null) {
          return const _ReaderScaffold(
            title: 'Study mode',
            child: Center(child: Text('Material not found.')),
          );
        }

        final title = material['title'] as String? ?? 'Study mode';
        final subjectName = material['subject']?['name'] as String? ?? '';
        final contentType = (material['contentType'] as String? ?? '').toLowerCase();
        if (_isPdfMaterial(material)) {
          final fileUrl = material['fileUrl'] as String?;
          if (fileUrl == null || fileUrl.isEmpty) {
            return _ReaderScaffold(
              title: title,
              child: const Center(child: Text('This PDF is not available right now.')),
            );
          }
          return _PdfMaterialReader(
            slug: widget.slug,
            title: title,
            subjectName: subjectName,
            contentType: contentType,
            fileUrl: fileUrl,
            loadSavedPage: _loadSavedPage,
            savePage: _savePage,
            cachePdf: _cachePdf,
            progressStore: _progressStore,
          );
        }

        if (_isReadableText(material)) {
          return _TextMaterialReader(
            slug: widget.slug,
            title: title,
            pages: _buildTextPages(material['contentText'] as String? ?? ''),
            subjectName: subjectName,
            contentType: contentType,
            loadSavedPage: _loadSavedPage,
            savePage: _savePage,
            progressStore: _progressStore,
          );
        }

        if (_isVideoMaterial(material)) {
          return _VideoMaterialReader(
            slug: widget.slug,
            title: title,
            subjectName: subjectName,
            contentType: contentType,
            youtubeEmbedUrl: material['youtubeEmbedUrl'] as String? ?? '',
            progressStore: _progressStore,
            resolveVideoId: _videoIdFromUrl,
          );
        }

        if (_isImageMaterial(material)) {
          return _ImageMaterialReader(
            slug: widget.slug,
            title: title,
            subjectName: subjectName,
            contentType: contentType,
            imageUrl: material['fileUrl'] as String? ?? '',
            progressStore: _progressStore,
          );
        }

        return _ReaderScaffold(
          title: title,
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
      },
    );
  }
}

class _PdfMaterialReader extends StatefulWidget {
  const _PdfMaterialReader({
    required this.slug,
    required this.title,
    required this.subjectName,
    required this.contentType,
    required this.fileUrl,
    required this.loadSavedPage,
    required this.savePage,
    required this.cachePdf,
    required this.progressStore,
  });

  final String slug;
  final String title;
  final String subjectName;
  final String contentType;
  final String fileUrl;
  final Future<int> Function(String slug, {bool textMode}) loadSavedPage;
  final Future<void> Function(String slug, int page, {bool textMode}) savePage;
  final Future<String?> Function(String url, String slug) cachePdf;
  final StudyProgressStore progressStore;

  @override
  State<_PdfMaterialReader> createState() => _PdfMaterialReaderState();
}

class _PdfMaterialReaderState extends State<_PdfMaterialReader> {
  int _currentPage = 0;
  int _pageCount = 0;
  late final Future<(String?, int)> _documentFuture;

  @override
  void initState() {
    super.initState();
    _documentFuture = () async {
      final filePath = await widget.cachePdf(widget.fileUrl, widget.slug);
      final savedPage = await widget.loadSavedPage(widget.slug);
      return (filePath, savedPage);
    }();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(String?, int)>(
      future: _documentFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _ReaderScaffold(
            title: widget.title,
            trailing: const _PageBadge(label: 'Opening...'),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final filePath = snapshot.data!.$1;
        final savedPage = snapshot.data!.$2;
        if (filePath == null) {
          return _ReaderScaffold(
            title: widget.title,
            child: const Center(child: Text('Could not prepare this PDF for reading.')),
          );
        }

        return _ReaderScaffold(
          title: widget.title,
          trailing: _PageBadge(
            label: _pageCount == 0 ? 'Loading...' : 'Page ${_currentPage + 1} / $_pageCount',
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
                  _currentPage = savedPage.clamp(0, (pages ?? 1) - 1);
                });
              },
              onPageChanged: (page, total) {
                final nextPage = page ?? 0;
                if (!mounted) return;
                setState(() {
                  _currentPage = nextPage;
                  _pageCount = total ?? _pageCount;
                });
                widget.savePage(widget.slug, nextPage);
                widget.progressStore.saveMaterial(
                  slug: widget.slug,
                  title: widget.title,
                  subjectName: widget.subjectName,
                  contentType: widget.contentType,
                  currentUnit: nextPage,
                  totalUnits: total ?? _pageCount,
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
}

class _TextMaterialReader extends StatefulWidget {
  const _TextMaterialReader({
    required this.slug,
    required this.title,
    required this.pages,
    required this.subjectName,
    required this.contentType,
    required this.loadSavedPage,
    required this.savePage,
    required this.progressStore,
  });

  final String slug;
  final String title;
  final List<String> pages;
  final String subjectName;
  final String contentType;
  final Future<int> Function(String slug, {bool textMode}) loadSavedPage;
  final Future<void> Function(String slug, int page, {bool textMode}) savePage;
  final StudyProgressStore progressStore;

  @override
  State<_TextMaterialReader> createState() => _TextMaterialReaderState();
}

class _TextMaterialReaderState extends State<_TextMaterialReader> {
  PageController? _pageController;
  int _currentPage = 0;
  late final Future<int> _savedPageFuture;

  @override
  void initState() {
    super.initState();
    _savedPageFuture = widget.loadSavedPage(widget.slug, textMode: true);
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pages.isEmpty) {
      return _ReaderScaffold(
        title: widget.title,
        child: const Center(child: Text('There is no readable text in this material yet.')),
      );
    }

    return FutureBuilder<int>(
      future: _savedPageFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _ReaderScaffold(
            title: widget.title,
            trailing: const _PageBadge(label: 'Opening...'),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final initialPage = snapshot.data!.clamp(0, widget.pages.length - 1);
        _pageController ??= PageController(initialPage: initialPage);
        _currentPage = _pageController!.hasClients ? _currentPage : initialPage;

        return _ReaderScaffold(
          title: widget.title,
          trailing: _PageBadge(label: 'Page ${_currentPage + 1} / ${widget.pages.length}'),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF7F0E1), Color(0xFFEEE4CF)],
              ),
            ),
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.pages.length,
              onPageChanged: (page) {
                setState(() => _currentPage = page);
                widget.savePage(widget.slug, page, textMode: true);
                widget.progressStore.saveMaterial(
                  slug: widget.slug,
                  title: widget.title,
                  subjectName: widget.subjectName,
                  contentType: widget.contentType,
                  currentUnit: page,
                  totalUnits: widget.pages.length,
                );
              },
              itemBuilder: (context, index) {
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
                                if (widget.subjectName.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: DesignTokens.primary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      widget.subjectName,
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
                            const SizedBox(height: 20),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Text(
                                  widget.pages[index],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    height: 1.75,
                                    color: DesignTokens.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text(
                                  index == widget.pages.length - 1 ? 'End of notes' : 'Swipe for next page',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: DesignTokens.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
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
}

class _VideoMaterialReader extends StatefulWidget {
  const _VideoMaterialReader({
    required this.slug,
    required this.title,
    required this.subjectName,
    required this.contentType,
    required this.youtubeEmbedUrl,
    required this.progressStore,
    required this.resolveVideoId,
  });

  final String slug;
  final String title;
  final String subjectName;
  final String contentType;
  final String youtubeEmbedUrl;
  final StudyProgressStore progressStore;
  final String? Function(String url) resolveVideoId;

  @override
  State<_VideoMaterialReader> createState() => _VideoMaterialReaderState();
}

class _VideoMaterialReaderState extends State<_VideoMaterialReader> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final videoId = widget.resolveVideoId(widget.youtubeEmbedUrl);
    if (videoId != null && videoId.isNotEmpty) {
      _controller = YoutubePlayerController(
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          strictRelatedVideos: true,
        ),
      )..loadVideoById(videoId: videoId);
      widget.progressStore.saveMaterial(
        slug: widget.slug,
        title: widget.title,
        subjectName: widget.subjectName,
        contentType: widget.contentType,
        currentUnit: 0,
        totalUnits: 1,
      );
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
      return _ReaderScaffold(
        title: widget.title,
        child: const Center(child: Text('This video could not be opened in study mode.')),
      );
    }

    return _ReaderScaffold(
      title: widget.title,
      trailing: const _PageBadge(label: 'Video lesson'),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.subjectName.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: _ReaderTag(label: widget.subjectName),
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
          const _ReaderTip(
            text: 'Watch inside the app, then use the summary, flashcards, or quiz on the material page to reinforce it.',
          ),
        ],
      ),
    );
  }
}

class _ImageMaterialReader extends StatefulWidget {
  const _ImageMaterialReader({
    required this.slug,
    required this.title,
    required this.subjectName,
    required this.contentType,
    required this.imageUrl,
    required this.progressStore,
  });

  final String slug;
  final String title;
  final String subjectName;
  final String contentType;
  final String imageUrl;
  final StudyProgressStore progressStore;

  @override
  State<_ImageMaterialReader> createState() => _ImageMaterialReaderState();
}

class _ImageMaterialReaderState extends State<_ImageMaterialReader> {
  @override
  void initState() {
    super.initState();
    widget.progressStore.saveMaterial(
      slug: widget.slug,
      title: widget.title,
      subjectName: widget.subjectName,
      contentType: widget.contentType,
      currentUnit: 0,
      totalUnits: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ReaderScaffold(
      title: widget.title,
      trailing: const _PageBadge(label: 'Image material'),
      child: Container(
        color: const Color(0xFF101114),
        child: Column(
          children: [
            if (widget.subjectName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _ReaderTag(label: widget.subjectName),
                ),
              ),
            Expanded(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Center(
                  child: Image.network(
                    widget.imageUrl,
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
              child: _ReaderTip(
                text: 'Pinch to zoom and inspect diagrams without leaving the app.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderScaffold extends StatelessWidget {
  const _ReaderScaffold({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, overflow: TextOverflow.ellipsis),
        actions: [
          if (trailing != null) Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: trailing),
          ),
        ],
      ),
      body: child,
    );
  }
}

class _PageBadge extends StatelessWidget {
  const _PageBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReaderTag extends StatelessWidget {
  const _ReaderTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReaderTip extends StatelessWidget {
  const _ReaderTip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }
}
