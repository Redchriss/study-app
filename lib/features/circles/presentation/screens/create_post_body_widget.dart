part of 'create_post_screen.dart';

class PostTypeBody extends StatelessWidget {
  final String postType;
  final TextEditingController urlCtrl;
  final ValueChanged<String> onUrlChanged;
  final String? previewTitle, previewThumbnail, previewDescription;
  final TextEditingController bodyCtrl;
  final void Function(String, String) onInsertMarkdown;
  final String? imagePath;
  final VoidCallback onPickImage;
  final List<GalleryItem> galleryItems;
  final VoidCallback onPickGalleryImages;
  final ValueChanged<int> onRemoveGalleryItem;
  final void Function(int, int)? onReorderGallery;
  final String? videoPath;
  final VoidCallback onPickVideo;
  final List<TextEditingController> pollOptions;
  final int pollDurationHours;
  final VoidCallback onAddPollOption;
  final ValueChanged<int> onRemovePollOption;
  final ValueChanged<int> onDurationChanged;
  final bool isOc, isSpoiler;
  final ValueChanged<bool> onOcChanged, onSpoilerChanged;

  const PostTypeBody({
    super.key,
    required this.postType,
    required this.urlCtrl,
    required this.onUrlChanged,
    this.previewTitle,
    this.previewThumbnail,
    this.previewDescription,
    required this.bodyCtrl,
    required this.onInsertMarkdown,
    this.imagePath,
    required this.onPickImage,
    required this.galleryItems,
    required this.onPickGalleryImages,
    required this.onRemoveGalleryItem,
    this.onReorderGallery,
    this.videoPath,
    required this.onPickVideo,
    required this.pollOptions,
    required this.pollDurationHours,
    required this.onAddPollOption,
    required this.onRemovePollOption,
    required this.onDurationChanged,
    required this.isOc,
    required this.onOcChanged,
    required this.isSpoiler,
    required this.onSpoilerChanged,
  });

  @override
  Widget build(BuildContext context) {
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
                child: Image.file(File(imagePath!),
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
}
