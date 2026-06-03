part of 'create_post_screen.dart';

mixin _PostFormFields on ConsumerState<CreatePostScreen> {
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
  Timer? _draftTimer;

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
}
