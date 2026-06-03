part of 'create_post_screen.dart';

mixin _CreatePostSubmitMixin
    on ConsumerState<CreatePostScreen>, _PostFormFields, _CreatePostDraftMixin {
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
}
