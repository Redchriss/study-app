import 'dart:io';

import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import '../../../../core/graphql/queries/queries.dart';
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
            fileUrl: fileUrl,
            loadSavedPage: _loadSavedPage,
            savePage: _savePage,
            cachePdf: _cachePdf,
          );
        }

        if (_isReadableText(material)) {
          return _TextMaterialReader(
            slug: widget.slug,
            title: title,
            pages: _buildTextPages(material['contentText'] as String? ?? ''),
            subjectName: material['subject']?['name'] as String? ?? '',
            loadSavedPage: _loadSavedPage,
            savePage: _savePage,
          );
        }

        return _ReaderScaffold(
          title: title,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Study mode is currently available for PDF and text materials.',
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
    required this.fileUrl,
    required this.loadSavedPage,
    required this.savePage,
    required this.cachePdf,
  });

  final String slug;
  final String title;
  final String fileUrl;
  final Future<int> Function(String slug, {bool textMode}) loadSavedPage;
  final Future<void> Function(String slug, int page, {bool textMode}) savePage;
  final Future<String?> Function(String url, String slug) cachePdf;

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
    required this.loadSavedPage,
    required this.savePage,
  });

  final String slug;
  final String title;
  final List<String> pages;
  final String subjectName;
  final Future<int> Function(String slug, {bool textMode}) loadSavedPage;
  final Future<void> Function(String slug, int page, {bool textMode}) savePage;

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
