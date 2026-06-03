library create_post_screen;

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

part 'create_post_screen_fields.dart';
part 'create_post_screen_draft.dart';
part 'create_post_screen_media.dart';
part 'create_post_screen_submit.dart';
part 'create_post_crosspost_banner.dart';
part 'create_post_body_widget.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  final String? communitySlug;
  final Map<String, dynamic>? crosspostOf;
  const CreatePostScreen({super.key, this.communitySlug, this.crosspostOf});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen>
    with
        _PostFormFields,
        _CreatePostDraftMixin,
        _CreatePostMediaMixin,
        _CreatePostSubmitMixin {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postBody = PostTypeBody(
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
