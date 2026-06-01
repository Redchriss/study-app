import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/pending_posts_provider.dart';
import 'create_post_widgets.dart';
import 'create_post_submit.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  final String? communitySlug;
  final Map<String, dynamic>? crosspostOf;
  const CreatePostScreen({super.key, this.communitySlug, this.crosspostOf});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  String? _communitySlug;
  String _postType = 'text';
  bool _isOc = false;
  bool _isSpoiler = false;
  bool _submitting = false;
  String? _imageBase64;
  String? _imagePath;
  String? _videoBase64;
  String? _videoPath;
  String? _flairId;
  String? _linkPreviewTitle;
  String? _linkPreviewThumbnail;
  String? _linkPreviewDescription;
  int _pollDurationHours = 24;
  Timer? _linkDebounce;
  final _galleryItems = <GalleryItem>[];
  final _pollOptions = <TextEditingController>[];

  static const _draftKey = 'create_post_draft';
  Timer? _draftTimer;

  @override
  void initState() {
    super.initState();
    _communitySlug = widget.communitySlug;
    _pollOptions.add(TextEditingController());
    _pollOptions.add(TextEditingController());
    if (widget.crosspostOf != null) _postType = 'crosspost';
    _titleCtrl.addListener(_onDraftChanged);
    _bodyCtrl.addListener(_onDraftChanged);
    _urlCtrl.addListener(_onDraftChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkStaleDraft());
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_onDraftChanged);
    _bodyCtrl.removeListener(_onDraftChanged);
    _urlCtrl.removeListener(_onDraftChanged);
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _urlCtrl.dispose();
    _linkDebounce?.cancel();
    _draftTimer?.cancel();
    for (final c in _pollOptions) {
      c.dispose();
    }
    for (final g in _galleryItems) {
      g.captionCtrl.dispose();
    }
    super.dispose();
  }

  void _onDraftChanged() {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(seconds: 3), _saveDraft);
  }

  void _saveDraft() {
    try {
      final box = Hive.box<String>('post_drafts');
      box.put(
          _draftKey,
          jsonEncode({
            'title': _titleCtrl.text,
            'body': _bodyCtrl.text,
            'url': _urlCtrl.text,
            'postType': _postType,
            'isOc': _isOc,
            'isSpoiler': _isSpoiler,
            'communitySlug': _communitySlug,
          }));
    } catch (_) {}
  }

  void _clearDraft() {
    _draftTimer?.cancel();
    try {
      final box = Hive.box<String>('post_drafts');
      box.delete(_draftKey);
    } catch (_) {}
  }

  void _checkStaleDraft() {
    try {
      final box = Hive.box<String>('post_drafts');
      final json = box.get(_draftKey);
      if (json == null || json.isEmpty) return;
      final draft = jsonDecode(json) as Map<String, dynamic>;
      final title = draft['title'] as String? ?? '';
      if (title.isEmpty) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Resume draft?'),
          content: Text('You have a saved draft: "$title"'),
          actions: [
            TextButton(
              onPressed: () {
                _clearDraft();
                Navigator.pop(ctx);
              },
              child: const Text('Discard'),
            ),
            TextButton(
              onPressed: () {
                _restoreDraft(draft);
                Navigator.pop(ctx);
              },
              child: const Text('Resume'),
            ),
          ],
        ),
      );
    } catch (_) {}
  }

  void _restoreDraft(Map<String, dynamic> draft) {
    _titleCtrl.text = draft['title'] as String? ?? '';
    _bodyCtrl.text = draft['body'] as String? ?? '';
    _urlCtrl.text = draft['url'] as String? ?? '';
    setState(() {
      _postType = draft['postType'] as String? ?? 'text';
      _isOc = draft['isOc'] as bool? ?? false;
      _isSpoiler = draft['isSpoiler'] as bool? ?? false;
      if (draft['communitySlug'] != null) {
        _communitySlug = draft['communitySlug'] as String?;
      }
    });
  }

  bool get _isValid {
    if (_communitySlug?.isEmpty ?? true) return false;
    if (_titleCtrl.text.trim().isEmpty) return false;
    if (_postType == 'link' && _urlCtrl.text.trim().isEmpty) return false;
    if (_postType == 'image' && _imageBase64 == null) return false;
    if (_postType == 'gallery' && _galleryItems.isEmpty) return false;
    if (_postType == 'video' && _videoBase64 == null) return false;
    if (_postType == 'poll' &&
        _pollOptions.where((c) => c.text.trim().isNotEmpty).length < 2)
      return false;
    return true;
  }

  Future<void> _pickMedia({required bool video}) async {
    final result = video ? await pickPostVideo() : await pickPostImage();
    if (result == null) return;
    setState(() {
      if (video) {
        _videoBase64 = result.base64;
        _videoPath = result.path;
      } else {
        _imageBase64 = result.base64;
        _imagePath = result.path;
      }
    });
  }

  Future<void> _pickGalleryImages() async {
    final results = await pickPostGalleryImages();
    setState(() {
      for (final r in results) {
        _galleryItems.add(GalleryItem(
            imageBase64: r.base64,
            imagePath: r.path,
            captionCtrl: TextEditingController()));
      }
    });
  }

  void _onReorderGallery(int oldI, int newI) {
    setState(() {
      final item = _galleryItems.removeAt(oldI);
      _galleryItems.insert(newI, item);
    });
  }

  void _onUrlChanged(String url) {
    _linkDebounce?.cancel();
    if (url.trim().isEmpty || _postType != 'link') {
      setState(() {
        _linkPreviewTitle = null;
        _linkPreviewThumbnail = null;
        _linkPreviewDescription = null;
      });
      return;
    }
    _linkDebounce = Timer(const Duration(milliseconds: 500), () {
      final preview = parseLinkPreview(url);
      setState(() {
        _linkPreviewTitle = preview?.title;
        _linkPreviewDescription = preview?.description;
      });
    });
  }

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);

    final user = ref.read(authProvider).user;
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final pendings = ref.read(pendingPostsProvider.notifier);
    pendings.add(PendingEntry(
      tempId: tempId,
      type: 'post',
      groupKey: _communitySlug ?? '',
      data: {
        'id': tempId,
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'slug': tempId,
        'postType': _postType,
        'author': {
          'id': user?['id']?.toString() ?? '',
          'username': user?['username']?.toString() ?? 'me',
        },
        'community': {'slug': _communitySlug, 'name': _communitySlug},
        'createdAt': DateTime.now().toIso8601String(),
        'upvoteCount': 0,
        'downvoteCount': 0,
        'score': 0,
        'commentCount': 0,
        'fuzzedUpvotes': 0,
        'fuzzedDownvotes': 0,
        'fuzzedScore': 0,
        'isPending': true,
        'isOc': _isOc,
        'isSpoiler': _isSpoiler,
        'isPinned': false,
        'isLocked': false,
        'imageUrl': null,
        'flairText': null,
      },
    ));

    try {
      await submitPost(
        ref: ref,
        context: context,
        communitySlug: _communitySlug,
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        postType: _postType,
        url: _urlCtrl.text.trim(),
        imageBase64: _imageBase64,
        videoBase64: _videoBase64,
        isOc: _isOc,
        isSpoiler: _isSpoiler,
        flairId: _flairId,
        galleryItems: _galleryItems
            .map((g) => (base64: g.imageBase64, caption: g.captionCtrl.text))
            .toList(),
        pollOptions: _pollOptions.map((c) => c.text.trim()).toList(),
        pollDurationHours: _pollDurationHours,
        crosspostOf: widget.crosspostOf,
        onError: (msg) {
          if (!mounted) return;
          pendings.fail(tempId, msg);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(msg), backgroundColor: DesignTokens.error));
        },
        onSuccess: () {
          pendings.remove(tempId);
          _clearDraft();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Post created!'),
              backgroundColor: DesignTokens.success));
          context.pop();
        },
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget buildPostTypeBody({
    required String postType,
    required TextEditingController urlCtrl,
    required ValueChanged<String> onUrlChanged,
    required String? previewTitle,
    required String? previewThumbnail,
    required String? previewDescription,
    required TextEditingController bodyCtrl,
    required void Function(String, String) onInsertMarkdown,
    required String? imagePath,
    required VoidCallback onPickImage,
    required List<GalleryItem> galleryItems,
    required VoidCallback onPickGalleryImages,
    required ValueChanged<int> onRemoveGalleryItem,
    required void Function(int, int)? onReorderGallery,
    required String? videoPath,
    required VoidCallback onPickVideo,
    required List<TextEditingController> pollOptions,
    required int pollDurationHours,
    required VoidCallback onAddPollOption,
    required ValueChanged<int> onRemovePollOption,
    required ValueChanged<int> onDurationChanged,
    required bool isOc,
    required ValueChanged<bool> onOcChanged,
    required bool isSpoiler,
    required ValueChanged<bool> onSpoilerChanged,
  }) {
    switch (postType) {
      case 'link':
        return LinkPreviewFetcher(
          urlCtrl: urlCtrl,
          onUrlChanged: onUrlChanged,
          previewTitle: previewTitle,
          previewThumbnail: previewThumbnail,
          previewDescription: previewDescription,
        );
      case 'image':
        return Column(
          children: [
            if (imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(imagePath),
                    height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onPickImage,
              icon: const Icon(Icons.image_outlined),
              label: Text(imagePath != null ? 'Change image' : 'Select image'),
            ),
          ],
        );
      case 'gallery':
        return GalleryPicker(
          items: galleryItems,
          onPick: onPickGalleryImages,
          onRemove: onRemoveGalleryItem,
          onReorder: onReorderGallery,
        );
      case 'video':
        return Column(
          children: [
            if (videoPath != null)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(Icons.videocam_rounded,
                      size: 48, color: DesignTokens.textTertiary),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onPickVideo,
              icon: const Icon(Icons.videocam_outlined),
              label: Text(videoPath != null ? 'Change video' : 'Select video'),
            ),
          ],
        );
      case 'poll':
        return PollDurationSelector(
          options: pollOptions,
          duration: pollDurationHours,
          onAddOption: onAddPollOption,
          onRemoveOption: onRemovePollOption,
          onDurationChanged: onDurationChanged,
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkdownToolbar(onInsert: onInsertMarkdown),
            TextField(
              controller: bodyCtrl,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Write your post body (Markdown supported)...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postBody = buildPostTypeBody(
        postType: _postType,
        urlCtrl: _urlCtrl,
        onUrlChanged: _onUrlChanged,
        previewTitle: _linkPreviewTitle,
        previewThumbnail: _linkPreviewThumbnail,
        previewDescription: _linkPreviewDescription,
        bodyCtrl: _bodyCtrl,
        onInsertMarkdown: (p, s) {
          insertMarkdown(_bodyCtrl, p, s);
          setState(() {});
        },
        imagePath: _imagePath,
        onPickImage: () => _pickMedia(video: false),
        galleryItems: _galleryItems,
        onPickGalleryImages: _pickGalleryImages,
        onRemoveGalleryItem: (i) {
          _galleryItems[i].captionCtrl.dispose();
          setState(() => _galleryItems.removeAt(i));
        },
        onReorderGallery: _onReorderGallery,
        videoPath: _videoPath,
        onPickVideo: () => _pickMedia(video: true),
        pollOptions: _pollOptions,
        pollDurationHours: _pollDurationHours,
        onAddPollOption: () {
          if (_pollOptions.length < 6)
            setState(() => _pollOptions.add(TextEditingController()));
        },
        onRemovePollOption: (i) {
          if (_pollOptions.length > 2) {
            _pollOptions[i].dispose();
            setState(() => _pollOptions.removeAt(i));
          }
        },
        onDurationChanged: (v) => setState(() => _pollDurationHours = v),
        isOc: _isOc,
        onOcChanged: (v) => setState(() => _isOc = v),
        isSpoiler: _isSpoiler,
        onSpoilerChanged: (v) => setState(() => _isSpoiler = v));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Post',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _isValid
                            ? DesignTokens.primary
                            : DesignTokens.textTertiary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.crosspostOf != null)
              _CrosspostBanner(post: widget.crosspostOf!),
            CommunityPicker(
                selected: _communitySlug,
                onChanged: (v) => setState(() => _communitySlug = v),
                onFlairChanged: (fid) => setState(() => _flairId = fid),
                flairId: _flairId),
            const SizedBox(height: 16),
            Text('Post Type',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            PostTypeSelector(
                postTypes: kPostTypes,
                selected: _postType,
                onChanged: (v) => setState(() => _postType = v)),
            const SizedBox(height: 16),
            TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                    labelText: 'Title', border: OutlineInputBorder()),
                maxLength: 300,
                onChanged: (_) => setState(() {})),
            const SizedBox(height: 12),
            postBody,
          ],
        ),
      ),
    );
  }
}

class _CrosspostBanner extends StatelessWidget {
  final Map<String, dynamic> post;
  const _CrosspostBanner({required this.post});

  @override
  Widget build(BuildContext context) {
    final author = post['author'] as Map<String, dynamic>?;
    final community = post['community'] as Map<String, dynamic>?;
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DesignTokens.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.repeat_rounded,
              size: 20, color: DesignTokens.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Crossposting',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: DesignTokens.primary)),
                const SizedBox(height: 2),
                Text(post['title']?.toString() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                    'by u/${author?['username'] ?? 'unknown'} in y/${community?['name'] ?? ''}',
                    style: const TextStyle(
                        fontSize: 11, color: DesignTokens.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
