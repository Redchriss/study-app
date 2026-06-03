part of 'create_post_screen.dart';

mixin _CreatePostMediaMixin
    on ConsumerState<CreatePostScreen>, _PostFormFields {
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
}
