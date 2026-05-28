import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import 'material_reader_helpers.dart';
import 'material_reader_models.dart';
import 'material_reader_services.dart';
import 'reader_chrome.dart';

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
        child: const Center(
            child: Text('This video could not be opened in study mode.')),
      );
    }

    return ReaderScaffold(
      title: widget.material.title,
      trailing: const ReaderPageBadge(label: 'Video lesson'),
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
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.material.subjectName.isNotEmpty) ...[
            Align(
                alignment: Alignment.centerLeft,
                child: ReaderTag(label: widget.material.subjectName)),
            const SizedBox(height: 12),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: YoutubePlayer(controller: _controller!, aspectRatio: 16 / 9),
          ),
          const SizedBox(height: 16),
          const ReaderTip(
              text:
                  'Watch inside the app, then use quick quiz, flashcards, or AI help without leaving study mode.'),
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
