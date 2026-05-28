import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';
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
  final List<GalleryItem> _galleryItems = [];
  final _pollOptions = <TextEditingController>[];

  @override
  void initState() {
    super.initState();
    _communitySlug = widget.communitySlug;
    _pollOptions.add(TextEditingController());
    _pollOptions.add(TextEditingController());
    if (widget.crosspostOf != null) _postType = 'crosspost';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _urlCtrl.dispose();
    _linkDebounce?.cancel();
    for (final c in _pollOptions) { c.dispose(); }
    for (final g in _galleryItems) { g.captionCtrl.dispose(); }
    super.dispose();
  }

  bool get _isValid {
    if (_communitySlug?.isEmpty ?? true) return false;
    if (_titleCtrl.text.trim().isEmpty) return false;
    if (_postType == 'link' && _urlCtrl.text.trim().isEmpty) return false;
    if (_postType == 'image' && _imageBase64 == null) return false;
    if (_postType == 'gallery' && _galleryItems.isEmpty) return false;
    if (_postType == 'video' && _videoBase64 == null) return false;
    if (_postType == 'poll' && _pollOptions.where((c) => c.text.trim().isNotEmpty).length < 2) return false;
    return true;
  }

  Future<void> _pickMedia({required bool video}) async {
    final result = video ? await pickPostVideo() : await pickPostImage();
    if (result == null) return;
    setState(() {
      if (video) { _videoBase64 = result.base64; _videoPath = result.path; }
      else { _imageBase64 = result.base64; _imagePath = result.path; }
    });
  }

  Future<void> _pickGalleryImages() async {
    final results = await pickPostGalleryImages();
    setState(() {
      for (final r in results) {
        _galleryItems.add(GalleryItem(imageBase64: r.base64, imagePath: r.path, captionCtrl: TextEditingController()));
      }
    });
  }

  void _onUrlChanged(String url) {
    _linkDebounce?.cancel();
    if (url.trim().isEmpty || _postType != 'link') {
      setState(() { _linkPreviewTitle = null; _linkPreviewThumbnail = null; _linkPreviewDescription = null; });
      return;
    }
    _linkDebounce = Timer(const Duration(milliseconds: 500), () {
      final preview = parseLinkPreview(url);
      setState(() { _linkPreviewTitle = preview?.title; _linkPreviewDescription = preview?.description; });
    });
  }

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);
    try {
      await submitPost(ref: ref, context: context, communitySlug: _communitySlug, title: _titleCtrl.text.trim(), body: _bodyCtrl.text.trim(), postType: _postType, url: _urlCtrl.text.trim(), imageBase64: _imageBase64, videoBase64: _videoBase64, isOc: _isOc, isSpoiler: _isSpoiler, flairId: _flairId, pollOptions: _pollOptions.map((c) => c.text.trim()).toList(), pollDurationHours: _pollDurationHours, onError: (msg) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: DesignTokens.error)); }, onSuccess: () { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post created!'), backgroundColor: DesignTokens.success)); context.pop(); });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postBody = buildPostTypeBody(postType: _postType, urlCtrl: _urlCtrl, onUrlChanged: _onUrlChanged, previewTitle: _linkPreviewTitle, previewThumbnail: _linkPreviewThumbnail, previewDescription: _linkPreviewDescription, bodyCtrl: _bodyCtrl, onInsertMarkdown: (p, s) { insertMarkdown(_bodyCtrl, p, s); setState(() {}); }, imagePath: _imagePath, onPickImage: () => _pickMedia(video: false), galleryItems: _galleryItems, onPickGalleryImages: _pickGalleryImages, onRemoveGalleryItem: (i) { _galleryItems[i].captionCtrl.dispose(); setState(() => _galleryItems.removeAt(i)); }, videoPath: _videoPath, onPickVideo: () => _pickMedia(video: true), pollOptions: _pollOptions, pollDurationHours: _pollDurationHours, onAddPollOption: () { if (_pollOptions.length < 6) setState(() => _pollOptions.add(TextEditingController())); }, onRemovePollOption: (i) { if (_pollOptions.length > 2) { _pollOptions[i].dispose(); setState(() => _pollOptions.removeAt(i)); } }, onDurationChanged: (v) => setState(() => _pollDurationHours = v), isOc: _isOc, onOcChanged: (v) => setState(() => _isOc = v), isSpoiler: _isSpoiler, onSpoilerChanged: (v) => setState(() => _isSpoiler = v));
    final appBar = AppBar(title: const Text('Create Post'), actions: [TextButton(onPressed: _submitting ? null : _submit, child: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text('Post', style: TextStyle(fontWeight: FontWeight.w700, color: _isValid ? DesignTokens.primary : DesignTokens.textTertiary)))]);
    return Scaffold(appBar: appBar, body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [CommunityPicker(selected: _communitySlug, onChanged: (v) => setState(() => _communitySlug = v), onFlairChanged: (fid) => setState(() => _flairId = fid), flairId: _flairId), const SizedBox(height: 16), Text('Post Type', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)), const SizedBox(height: 8), PostTypeSelector(postTypes: kPostTypes, selected: _postType, onChanged: (v) => setState(() => _postType = v)), const SizedBox(height: 16), TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()), maxLength: 300, onChanged: (_) => setState(() {})), const SizedBox(height: 12), postBody])));
  }
}
