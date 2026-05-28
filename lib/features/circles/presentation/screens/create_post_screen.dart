import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

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

  // Gallery state
  final List<_GalleryItem> _galleryItems = [];

  final _pollOptions = <TextEditingController>[];

  final _postTypes = [
    {'key': 'text', 'icon': '📝', 'label': 'Text'},
    {'key': 'link', 'icon': '🔗', 'label': 'Link'},
    {'key': 'image', 'icon': '🖼', 'label': 'Image'},
    {'key': 'gallery', 'icon': '🎠', 'label': 'Gallery'},
    {'key': 'video', 'icon': '🎬', 'label': 'Video'},
    {'key': 'poll', 'icon': '📊', 'label': 'Poll'},
  ];

  @override
  void initState() {
    super.initState();
    _communitySlug = widget.communitySlug;
    _addPollOption();
    _addPollOption();
    if (widget.crosspostOf != null) {
      _postType = 'crosspost';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _urlCtrl.dispose();
    _linkDebounce?.cancel();
    for (final c in _pollOptions) {
      c.dispose();
    }
    for (final g in _galleryItems) {
      g.captionCtrl.dispose();
    }
    super.dispose();
  }

  bool get _isValid {
    if (_communitySlug == null || _communitySlug!.isEmpty) return false;
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final b64 = base64Encode(bytes);
    setState(() {
      _imageBase64 = b64;
      _imagePath = file.path;
    });
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final b64 = base64Encode(bytes);
    setState(() {
      _videoBase64 = b64;
      _videoPath = file.path;
    });
  }

  Future<void> _pickGalleryImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 85, maxWidth: 1920);
    if (files.isEmpty) return;
    for (final file in files) {
      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);
      setState(() {
        _galleryItems.add(_GalleryItem(
          imageBase64: b64,
          imagePath: file.path,
          captionCtrl: TextEditingController(),
        ));
      });
    }
  }

  void _removeGalleryItem(int index) {
    _galleryItems[index].captionCtrl.dispose();
    setState(() => _galleryItems.removeAt(index));
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
    _linkDebounce = Timer(const Duration(milliseconds: 500), () async {
      // Simple client-side link preview extraction
      try {
        final parsed = Uri.tryParse(url.trim());
        if (parsed != null && parsed.host.isNotEmpty) {
          setState(() {
            _linkPreviewTitle = parsed.host.replaceFirst('www.', '');
            _linkPreviewDescription = 'Loading preview...';
          });
          // Note: Full OG preview would use a backend extractLinkPreview mutation
        }
      } catch (_) {}
    });
  }

  void _addPollOption() {
    if (_pollOptions.length >= 6) return;
    setState(() => _pollOptions.add(TextEditingController()));
  }

  void _removePollOption(int i) {
    if (_pollOptions.length <= 2) return;
    _pollOptions[i].dispose();
    setState(() => _pollOptions.removeAt(i));
  }

  /// Insert markdown formatting around selected text
  void _insertMarkdown(String prefix, String suffix) {
    final selection = _bodyCtrl.selection;
    final text = _bodyCtrl.text;
    if (selection.isValid && selection.start != selection.end) {
      final selected = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
          selection.start, selection.end, '$prefix$selected$suffix');
      _bodyCtrl.text = newText;
      _bodyCtrl.selection = TextSelection.collapsed(
          offset: selection.start +
              prefix.length +
              selected.length +
              suffix.length);
    } else {
      final cursorPos = selection.baseOffset;
      final newText = '$prefix$suffix';
      _bodyCtrl.text =
          text.substring(0, cursorPos) + newText + text.substring(cursorPos);
      _bodyCtrl.selection =
          TextSelection.collapsed(offset: cursorPos + prefix.length);
    }
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);
    try {
      final client = ref.read(graphqlClientProvider);
      final vars = {
        'communitySlug': _communitySlug,
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'postType': _postType.toUpperCase(),
        'url': _postType == 'link' ? _urlCtrl.text.trim() : null,
        'imageBase64': _postType == 'image' ? _imageBase64 : null,
        'videoBase64': _postType == 'video' ? _videoBase64 : null,
        'isOc': _isOc,
        'isSpoiler': _isSpoiler,
        if (_flairId != null) 'flairId': _flairId,
        if (_postType == 'poll')
          'pollOptions': _pollOptions
              .map((c) => c.text.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
        if (_postType == 'poll') 'pollDurationHours': _pollDurationHours,
      };
      final result = await client.mutate(MutationOptions(
        document: gql(kCreatePost),
        variables: vars,
      ));
      if (!mounted) return;
      if (result.hasException) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              graphQLErrorMessage(result.exception, 'Could not create post')),
          backgroundColor: DesignTokens.error,
        ));
        return;
      }
      final payload = result.data?['createPost'];
      final errors = (payload?['errors'] as List?)?.join(', ');
      if (errors != null && errors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errors),
          backgroundColor: DesignTokens.error,
        ));
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Post created!'),
        backgroundColor: DesignTokens.success,
      ));
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            _CommunityPicker(
              selected: _communitySlug,
              onChanged: (v) => setState(() => _communitySlug = v),
              onFlairChanged: (fid) => setState(() => _flairId = fid),
              flairId: _flairId,
            ),
            const SizedBox(height: 16),
            Text('Post Type',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: _postTypes.map((t) {
                final selected = _postType == t['key'];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${t['icon']} ${t['label']}',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _postType = t['key'] as String),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              maxLength: 300,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            // LINK type: URL field + link preview
            if (_postType == 'link') ...[
              TextField(
                controller: _urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL',
                  border: OutlineInputBorder(),
                  hintText: 'https://...',
                ),
                onChanged: (v) {
                  setState(() {});
                  _onUrlChanged(v);
                },
              ),
              if (_linkPreviewTitle != null)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DesignTokens.border),
                    color: DesignTokens.surfaceVariant,
                  ),
                  child: Row(
                    children: [
                      if (_linkPreviewThumbnail != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(_linkPreviewThumbnail!,
                              width: 40, height: 40, fit: BoxFit.cover),
                        ),
                      if (_linkPreviewThumbnail != null)
                        const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_linkPreviewTitle ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                            if (_linkPreviewDescription != null)
                              Text(_linkPreviewDescription!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: DesignTokens.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            // TEXT type: body with markdown toolbar
            if (_postType == 'text') ...[
              // Markdown toolbar
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: DesignTokens.border),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _MarkdownToolbarButton(
                        label: 'B',
                        icon: Icons.format_bold,
                        isBold: true,
                        onTap: () => _insertMarkdown('**', '**'),
                      ),
                      _MarkdownToolbarButton(
                        label: 'I',
                        icon: Icons.format_italic,
                        onTap: () => _insertMarkdown('*', '*'),
                      ),
                      _MarkdownToolbarButton(
                        label: '',
                        icon: Icons.link,
                        onTap: () => _insertMarkdown('[', '](url)'),
                      ),
                      _MarkdownToolbarButton(
                        label: '',
                        icon: Icons.code,
                        onTap: () => _insertMarkdown('`', '`'),
                      ),
                      _MarkdownToolbarButton(
                        label: '',
                        icon: Icons.format_quote,
                        onTap: () => _insertMarkdown('> ', ''),
                      ),
                      _MarkdownToolbarButton(
                        label: '',
                        icon: Icons.format_list_bulleted,
                        onTap: () => _insertMarkdown('- ', ''),
                      ),
                      _MarkdownToolbarButton(
                        label: '',
                        icon: Icons.visibility_off,
                        onTap: () => _insertMarkdown('||', '||'),
                      ),
                    ],
                  ),
                ),
              ),
              TextField(
                controller: _bodyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Body (markdown)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
                minLines: 4,
              ),
            ],
            // IMAGE type
            if (_postType == 'image') ...[
              const SizedBox(height: 8),
              if (_imagePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(_imagePath!),
                      height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image_outlined),
                label: Text(_imagePath != null ? 'Change Image' : 'Pick Image'),
              ),
            ],
            // GALLERY type
            if (_postType == 'gallery') ...[
              const SizedBox(height: 8),
              if (_galleryItems.isNotEmpty)
                ..._galleryItems.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(File(e.value.imagePath),
                                width: 60, height: 60, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: e.value.captionCtrl,
                              decoration: InputDecoration(
                                labelText: 'Caption ${e.key + 1}',
                                border: const OutlineInputBorder(),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                size: 20, color: DesignTokens.error),
                            onPressed: () => _removeGalleryItem(e.key),
                          ),
                        ],
                      ),
                    )),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed:
                    _galleryItems.length < 20 ? _pickGalleryImages : null,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(_galleryItems.isNotEmpty
                    ? 'Add more (${_galleryItems.length}/20)'
                    : 'Select images'),
              ),
            ],
            // VIDEO type
            if (_postType == 'video') ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickVideo,
                icon: const Icon(Icons.videocam_outlined),
                label: Text(_videoPath != null ? 'Change Video' : 'Pick Video'),
              ),
              if (_videoPath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Selected: ${_videoPath!.split('/').last}',
                      style: const TextStyle(
                          fontSize: 12, color: DesignTokens.textSecondary)),
                ),
            ],
            // POLL type
            if (_postType == 'poll') ...[
              const SizedBox(height: 8),
              ..._pollOptions.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: e.value,
                            decoration: InputDecoration(
                              labelText: 'Option ${e.key + 1}',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon:
                              const Icon(Icons.remove_circle_outline, size: 20),
                          onPressed: _pollOptions.length > 2
                              ? () => _removePollOption(e.key)
                              : null,
                        ),
                      ],
                    ),
                  )),
              OutlinedButton.icon(
                onPressed: _pollOptions.length < 6 ? _addPollOption : null,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add option'),
              ),
              const SizedBox(height: 12),
              // Poll duration selector
              DropdownButtonFormField<int>(
                value: _pollDurationHours,
                decoration: const InputDecoration(
                  labelText: 'Poll duration',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 24, child: Text('1 day')),
                  DropdownMenuItem(value: 72, child: Text('3 days')),
                  DropdownMenuItem(value: 168, child: Text('7 days')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _pollDurationHours = v);
                },
              ),
            ],
            // Body field for image/video/gallery posts
            if (_postType == 'image' ||
                _postType == 'video' ||
                _postType == 'gallery') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _bodyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Body (markdown)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                minLines: 2,
              ),
            ],
            // OC / Spoiler toggles
            if (_postType != 'link' && _postType != 'crosspost') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  FilterChip(
                    label: const Text('OC', style: TextStyle(fontSize: 12)),
                    selected: _isOc,
                    onSelected: (v) => setState(() => _isOc = v),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label:
                        const Text('Spoiler', style: TextStyle(fontSize: 12)),
                    selected: _isSpoiler,
                    onSelected: (v) => setState(() => _isSpoiler = v),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GalleryItem {
  final String imageBase64;
  final String imagePath;
  final TextEditingController captionCtrl;
  _GalleryItem({
    required this.imageBase64,
    required this.imagePath,
    required this.captionCtrl,
  });
}

class _MarkdownToolbarButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isBold;
  final VoidCallback onTap;
  const _MarkdownToolbarButton({
    required this.label,
    required this.icon,
    this.isBold = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: DesignTokens.border)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: DesignTokens.textSecondary),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isBold ? FontWeight.w800 : FontWeight.normal,
                    color: DesignTokens.textSecondary,
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommunityPicker extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;
  final ValueChanged<String?>? onFlairChanged;
  final String? flairId;
  const _CommunityPicker({
    required this.selected,
    required this.onChanged,
    this.onFlairChanged,
    this.flairId,
  });

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(document: gql(kMyCommunities)),
      builder: (result, {fetchMore, refetch}) {
        final communities = (result.data?['myCommunities'] as List?) ?? [];
        final selectedCommunity = communities.firstWhere(
          (c) => c['slug'] == selected,
          orElse: () => null,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selected,
              decoration: const InputDecoration(
                labelText: 'Community',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Select community'),
              items: communities.map((c) {
                return DropdownMenuItem(
                  value: c['slug']?.toString(),
                  child: Text('y/${c['name'] ?? c['slug']}'),
                );
              }).toList(),
              onChanged: onChanged,
            ),
            // Flair picker
            if (selectedCommunity != null && onFlairChanged != null)
              _FlairPicker(
                communitySlug: selectedCommunity['slug']?.toString() ?? '',
                selectedFlairId: flairId,
                onChanged: onFlairChanged!,
              ),
          ],
        );
      },
    );
  }
}

class _FlairPicker extends StatelessWidget {
  final String communitySlug;
  final String? selectedFlairId;
  final ValueChanged<String?> onChanged;
  const _FlairPicker({
    required this.communitySlug,
    required this.selectedFlairId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(kCommunityFlairs),
        variables: {'slug': communitySlug},
      ),
      builder: (result, {fetchMore, refetch}) {
        final flairs = (result.data?['communityFlair'] as List?) ?? [];
        if (flairs.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: DropdownButtonFormField<String>(
            value: selectedFlairId,
            decoration: const InputDecoration(
              labelText: 'Flair',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            hint: const Text('Select flair (optional)'),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('None',
                    style: TextStyle(color: DesignTokens.textTertiary)),
              ),
              ...flairs.map((f) {
                return DropdownMenuItem(
                  value: f['id']?.toString(),
                  child: Text(f['text']?.toString() ?? ''),
                );
              }),
            ],
            onChanged: onChanged,
          ),
        );
      },
    );
  }
}
