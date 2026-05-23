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
  const CreatePostScreen({super.key, this.communitySlug});

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
  final _pollOptions = <TextEditingController>[];

  final _postTypes = [
    {'key': 'text', 'icon': '📝', 'label': 'Text'},
    {'key': 'link', 'icon': '🔗', 'label': 'Link'},
    {'key': 'image', 'icon': '🖼', 'label': 'Image'},
    {'key': 'video', 'icon': '🎬', 'label': 'Video'},
    {'key': 'poll', 'icon': '📊', 'label': 'Poll'},
  ];

  @override
  void initState() {
    super.initState();
    _communitySlug = widget.communitySlug;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _urlCtrl.dispose();
    for (final c in _pollOptions) c.dispose();
    super.dispose();
  }

  bool get _isValid {
    if (_communitySlug == null || _communitySlug!.isEmpty) return false;
    if (_titleCtrl.text.trim().isEmpty) return false;
    if (_postType == 'link' && _urlCtrl.text.trim().isEmpty) return false;
    if (_postType == 'image' && _imageBase64 == null) return false;
    if (_postType == 'video' && _videoBase64 == null) return false;
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

  void _addPollOption() {
    setState(() => _pollOptions.add(TextEditingController()));
  }

  void _removePollOption(int i) {
    _pollOptions[i].dispose();
    setState(() => _pollOptions.removeAt(i));
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
        if (_postType == 'poll')
          'pollOptions': _pollOptions
              .map((c) => c.text.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
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
                          style: TextStyle(
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
            if (_postType == 'link')
              TextField(
                controller: _urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL',
                  border: OutlineInputBorder(),
                  hintText: 'https://...',
                ),
                onChanged: (_) => setState(() {}),
              ),
            if (_postType == 'text')
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
                          onPressed: () => _removePollOption(e.key),
                        ),
                      ],
                    ),
                  )),
              OutlinedButton.icon(
                onPressed: _pollOptions.length < 10 ? _addPollOption : null,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add option'),
              ),
            ],
            if (_postType == 'text' ||
                _postType == 'image' ||
                _postType == 'video') ...[
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
            if (_postType != 'link') ...[
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

class _CommunityPicker extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;
  const _CommunityPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(document: gql(kMyCommunities)),
      builder: (result, {fetchMore, refetch}) {
        final communities = (result.data?['myCommunities'] as List?) ?? [];
        return DropdownButtonFormField<String>(
          value: selected,
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
        );
      },
    );
  }
}
