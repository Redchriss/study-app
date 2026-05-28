import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'create_post_widgets.dart';

// dart format off
Widget buildPostTypeBody({
  required String postType,
  required TextEditingController urlCtrl,
  required ValueChanged<String> onUrlChanged,
  String? previewTitle,
  String? previewThumbnail,
  String? previewDescription,
  required TextEditingController bodyCtrl,
  required void Function(String, String) onInsertMarkdown,
  String? imagePath,
  required VoidCallback onPickImage,
  required List<GalleryItem> galleryItems,
  required VoidCallback onPickGalleryImages,
  required ValueChanged<int> onRemoveGalleryItem,
  String? videoPath,
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
// dart format on
  return Column(
    children: [
      if (postType == 'link')
        LinkPreviewFetcher(
          urlCtrl: urlCtrl,
          onUrlChanged: onUrlChanged,
          previewTitle: previewTitle,
          previewThumbnail: previewThumbnail,
          previewDescription: previewDescription,
        ),
      if (postType == 'text') ...[
        MarkdownToolbar(onInsert: onInsertMarkdown),
        TextField(
          controller: bodyCtrl,
          decoration: const InputDecoration(
            labelText: 'Body (markdown)',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 8,
          minLines: 4,
        ),
      ],
      if (postType == 'image') ...[
        const SizedBox(height: 8),
        if (imagePath != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(imagePath),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onPickImage,
          icon: const Icon(Icons.image_outlined),
          label: Text(imagePath != null ? 'Change Image' : 'Pick Image'),
        ),
      ],
      if (postType == 'gallery')
        GalleryPicker(
          items: galleryItems,
          onPick: onPickGalleryImages,
          onRemove: onRemoveGalleryItem,
        ),
      if (postType == 'video') ...[
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onPickVideo,
          icon: const Icon(Icons.videocam_outlined),
          label: Text(videoPath != null ? 'Change Video' : 'Pick Video'),
        ),
        if (videoPath != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Selected: ${videoPath.split('/').last}',
              style: const TextStyle(
                fontSize: 12,
                color: DesignTokens.textSecondary,
              ),
            ),
          ),
      ],
      if (postType == 'poll')
        PollDurationSelector(
          options: pollOptions,
          duration: pollDurationHours,
          onAddOption: onAddPollOption,
          onRemoveOption: onRemovePollOption,
          onDurationChanged: onDurationChanged,
        ),
      if (postType == 'image' ||
          postType == 'video' ||
          postType == 'gallery') ...[
        const SizedBox(height: 12),
        TextField(
          controller: bodyCtrl,
          decoration: const InputDecoration(
            labelText: 'Body (markdown)',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
          minLines: 2,
        ),
      ],
      if (postType != 'link' && postType != 'crosspost') ...[
        const SizedBox(height: 12),
        Row(
          children: [
            FilterChip(
              label: const Text('OC', style: TextStyle(fontSize: 12)),
              selected: isOc,
              onSelected: onOcChanged,
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Spoiler', style: TextStyle(fontSize: 12)),
              selected: isSpoiler,
              onSelected: onSpoilerChanged,
            ),
          ],
        ),
      ],
    ],
  );
}

// dart format off
Future<void> submitPost({
  required WidgetRef ref,
  required BuildContext context,
  required String? communitySlug,
  required String title,
  required String body,
  required String postType,
  required String? url,
  required String? imageBase64,
  required String? videoBase64,
  required bool isOc,
  required bool isSpoiler,
  required String? flairId,
  required List<String> pollOptions,
  required int pollDurationHours,
  required void Function(String) onError,
  required VoidCallback onSuccess,
}) async {
// dart format on
  final client = ref.read(graphqlClientProvider);
  final vars = {
    'communitySlug': communitySlug,
    'title': title,
    'body': body,
    'postType': postType.toUpperCase(),
    if (postType == 'link') 'url': url,
    if (postType == 'image') 'imageBase64': imageBase64,
    if (postType == 'video') 'videoBase64': videoBase64,
    'isOc': isOc,
    'isSpoiler': isSpoiler,
    if (flairId != null) 'flairId': flairId,
    if (postType == 'poll')
      'pollOptions': pollOptions.where((s) => s.isNotEmpty).toList(),
    if (postType == 'poll') 'pollDurationHours': pollDurationHours,
  };
  final result = await client.mutate(MutationOptions(
    document: gql(kCreatePost),
    variables: vars,
  ));
  if (result.hasException) {
    onError(graphQLErrorMessage(result.exception, 'Could not create post'));
    return;
  }
  final payload = result.data?['createPost'];
  final errors = (payload?['errors'] as List?)?.join(', ');
  if (errors != null && errors.isNotEmpty) {
    onError(errors);
    return;
  }
  onSuccess();
}

({String title, String description})? parseLinkPreview(String url) {
  final parsed = Uri.tryParse(url.trim());
  if (parsed != null && parsed.host.isNotEmpty) {
    return (
      title: parsed.host.replaceFirst('www.', ''),
      description: 'Loading preview...',
    );
  }
  return null;
}

Timer? createLinkPreviewDebounce(String url, String postType,
    {required void Function(String?, String?) onPreview,
    required VoidCallback onClear}) {
  if (url.trim().isEmpty || postType != 'link') {
    onClear();
    return null;
  }
  return Timer(const Duration(milliseconds: 500), () {
    final preview = parseLinkPreview(url);
    onPreview(preview?.title, preview?.description);
  });
}
