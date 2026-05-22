import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class CircleNewPostForm extends StatefulWidget {
  const CircleNewPostForm(
      {super.key,
      required this.circleSlug,
      required this.onClose,
      required this.onPosted});
  final String circleSlug;
  final VoidCallback onClose;
  final VoidCallback onPosted;

  @override
  State<CircleNewPostForm> createState() => _CircleNewPostFormState();
}

class _CircleNewPostFormState extends State<CircleNewPostForm> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  File? _postImage;
  String _postType = 'discussion';
  bool _posting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    if (_titleCtrl.text.trim().isEmpty || _posting) return;
    setState(() => _posting = true);
    try {
      String? b64;
      if (_postImage != null) {
        final bytes = await _postImage!.readAsBytes();
        if (bytes.length > 3 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Image too large (max 3MB)'),
                  backgroundColor: DesignTokens.error),
            );
            setState(() => _posting = false);
          }
          return;
        }
        b64 = base64Encode(bytes);
      }
      final client = ProviderScope.containerOf(context, listen: false)
          .read(graphqlClientProvider);
      final result = await client.mutate(MutationOptions(
        document: gql(kCreatePost),
        variables: {
          'circleSlug': widget.circleSlug,
          'title': _titleCtrl.text.trim(),
          'content': _bodyCtrl.text.trim(),
          'postType': _postType,
          'imageBase64': b64,
        },
      ));
      if (!mounted) return;
      setState(() => _posting = false);
      if (result.hasException ||
          result.data?['createPost']?['success'] != true) {
        final msg = result.exception?.graphqlErrors.firstOrNull?.message ??
            (result.data?['createPost']?['errors'] as List?)
                ?.firstOrNull
                ?.toString() ??
            'unknown error';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to post: $msg'),
            backgroundColor: DesignTokens.error));
        return;
      }
      _titleCtrl.clear();
      _bodyCtrl.clear();
      setState(() => _postImage = null);
      widget.onPosted();
    } catch (e) {
      if (!mounted) return;
      setState(() => _posting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to post: $e'),
          backgroundColor: DesignTokens.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dark ? DesignTokens.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DesignTokens.primary.withValues(alpha: 0.2)),
        boxShadow: DesignTokens.shadowSm(dark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Create new post',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: 'Title',
                filled: true,
                fillColor: dark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              )),
          const SizedBox(height: 12),
          TextField(
              controller: _bodyCtrl,
              decoration: InputDecoration(
                labelText: 'Body',
                filled: true,
                fillColor: dark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
              maxLines: 4),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_postImage != null)
                Stack(children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_postImage!,
                          height: 64, width: 64, fit: BoxFit.cover)),
                  Positioned(
                      right: -4,
                      top: -4,
                      child: GestureDetector(
                        onTap: () => setState(() => _postImage = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: DesignTokens.error,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              size: 14, color: Colors.white),
                        ),
                      )),
                ])
              else
                AnimatedPress(
                  onTap: () async {
                    final x = await ImagePicker()
                        .pickImage(source: ImageSource.gallery, maxWidth: 1024);
                    if (x != null) setState(() => _postImage = File(x.path));
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                        color: DesignTokens.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.add_photo_alternate_rounded,
                        color: DesignTokens.primary, size: 28),
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _postType,
                  decoration: InputDecoration(
                    labelText: 'Post Type',
                    filled: true,
                    fillColor: dark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade50,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'discussion', child: Text('Discussion')),
                    DropdownMenuItem(
                        value: 'question', child: Text('Question')),
                    DropdownMenuItem(
                        value: 'resource', child: Text('Resource')),
                  ],
                  onChanged: (v) =>
                      setState(() => _postType = v ?? 'discussion'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: widget.onClose, child: const Text('Cancel')),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _posting ? null : _submitPost,
                style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12)),
                child: _posting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Post'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
