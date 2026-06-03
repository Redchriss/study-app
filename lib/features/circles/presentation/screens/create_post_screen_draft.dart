part of 'create_post_screen.dart';

mixin _CreatePostDraftMixin
    on ConsumerState<CreatePostScreen>, _PostFormFields {
  static const _draftKey = 'create_post_draft';

  void _onDraftChanged() {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(seconds: 3), _saveDraft);
  }

  void _saveDraft() {
    try {
      final box = Hive.box<String>('post_drafts');
      box.put(
          _draftKey,
          jsonEncode({
            'title': _titleCtrl.text,
            'body': _bodyCtrl.text,
            'url': _urlCtrl.text,
            'postType': _postType,
            'isOc': _isOc,
            'isSpoiler': _isSpoiler,
            'communitySlug': _communitySlug,
          }));
    } catch (_) {}
  }

  void _clearDraft() {
    _draftTimer?.cancel();
    try {
      final box = Hive.box<String>('post_drafts');
      box.delete(_draftKey);
    } catch (_) {}
  }

  void _checkStaleDraft() {
    try {
      final box = Hive.box<String>('post_drafts');
      final json = box.get(_draftKey);
      if (json == null || json.isEmpty) return;
      final draft = jsonDecode(json) as Map<String, dynamic>;
      final title = draft['title'] as String? ?? '';
      if (title.isEmpty) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Resume draft?'),
          content: Text('You have a saved draft: "$title"'),
          actions: [
            TextButton(
              onPressed: () {
                _clearDraft();
                Navigator.pop(ctx);
              },
              child: const Text('Discard'),
            ),
            TextButton(
              onPressed: () {
                _restoreDraft(draft);
                Navigator.pop(ctx);
              },
              child: const Text('Resume'),
            ),
          ],
        ),
      );
    } catch (_) {}
  }

  void _restoreDraft(Map<String, dynamic> draft) {
    _titleCtrl.text = draft['title'] as String? ?? '';
    _bodyCtrl.text = draft['body'] as String? ?? '';
    _urlCtrl.text = draft['url'] as String? ?? '';
    setState(() {
      _postType = draft['postType'] as String? ?? 'text';
      _isOc = draft['isOc'] as bool? ?? false;
      _isSpoiler = draft['isSpoiler'] as bool? ?? false;
      if (draft['communitySlug'] != null) {
        _communitySlug = draft['communitySlug'] as String?;
      }
    });
  }
}
