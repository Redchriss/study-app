part of 'circles_repository.dart';

/// A reference to a freshly created/crossposted post.
class CirclePostRef {
  final String id;
  final String slug;
  const CirclePostRef({required this.id, required this.slug});
}

/// Content mutations: creating/editing posts & comments, voting, saving,
/// polls, awards and the in-feed AI action.
extension CirclesRepositoryContentActions on CirclesRepository {
  // ---- Posts -------------------------------------------------------------

  Future<CirclePostRef> createPost({
    required String communitySlug,
    required String title,
    required String postType,
    String? body,
    String? url,
    String? imageBase64,
    String? videoBase64,
    List<Map<String, dynamic>>? galleryItems,
    String? flairId,
    bool? isOc,
    bool? isSpoiler,
    List<String>? pollOptions,
    int? pollDurationHours,
  }) async {
    final data = await _mutate(kCreatePost, variables: {
      'communitySlug': communitySlug,
      'title': title,
      'postType': postType,
      'body': body,
      'url': url,
      'imageBase64': imageBase64,
      'videoBase64': videoBase64,
      'galleryItems': galleryItems,
      'flairId': flairId,
      'isOc': isOc,
      'isSpoiler': isSpoiler,
      'pollOptions': pollOptions,
      'pollDurationHours': pollDurationHours,
    });
    final payload = asMap(data['createPost']);
    _throwIfPayloadErrors(payload);
    final post = asMap(payload?['post']);
    return CirclePostRef(
      id: asString(post?['id']),
      slug: asString(post?['slug']),
    );
  }

  Future<void> editPost({
    required String postId,
    String? title,
    String? body,
  }) async {
    final data = await _mutate(kEditPost,
        variables: {'postId': postId, 'title': title, 'body': body});
    _throwIfPayloadErrors(data['editPost']);
  }

  Future<bool> deletePost(String postId) async {
    final data = await _mutate(kDeletePost, variables: {'postId': postId});
    return _isSuccess(data['deletePost']);
  }

  Future<CirclePostRef> crosspost({
    required String originalPostId,
    required String communitySlug,
    String? title,
  }) async {
    final data = await _mutate(kCrosspost, variables: {
      'originalPostId': originalPostId,
      'communitySlug': communitySlug,
      'title': title,
    });
    final payload = asMap(data['crosspost']);
    _throwIfPayloadErrors(payload);
    final post = asMap(payload?['post']);
    return CirclePostRef(
      id: asString(post?['id']),
      slug: asString(post?['slug']),
    );
  }

  // ---- Votes & saves -----------------------------------------------------

  Future<void> votePost({required String postId, required int direction}) async {
    final data = await _mutate(kVotePost,
        variables: {'postId': postId, 'direction': direction});
    _throwIfPayloadErrors(data['votePost']);
  }

  Future<bool> savePost(String postId) async {
    final data = await _mutate(kSavePost, variables: {'postId': postId});
    return _isSuccess(data['savePost']);
  }

  Future<bool> unsavePost(String postId) async {
    final data = await _mutate(kUnsavePost, variables: {'postId': postId});
    return _isSuccess(data['unsavePost']);
  }

  Future<void> voteComment(
      {required String commentId, required int direction}) async {
    final data = await _mutate(kVoteComment,
        variables: {'commentId': commentId, 'direction': direction});
    _throwIfPayloadErrors(data['voteComment']);
  }

  Future<bool> saveComment(String commentId) async {
    final data = await _mutate(kSaveComment, variables: {'commentId': commentId});
    return _isSuccess(data['saveComment']);
  }

  Future<bool> unsaveComment(String commentId) async {
    final data =
        await _mutate(kUnsaveComment, variables: {'commentId': commentId});
    return _isSuccess(data['unsaveComment']);
  }

  // ---- Comments ----------------------------------------------------------

  Future<CircleComment?> addComment({
    required String postId,
    required String body,
    String? parentId,
  }) async {
    final data = await _mutate(kAddComment,
        variables: {'postId': postId, 'body': body, 'parentId': parentId});
    final payload = asMap(data['addComment']);
    _throwIfPayloadErrors(payload);
    final comment = asMap(payload?['comment']);
    return comment == null ? null : CircleComment.fromJson(comment);
  }

  Future<void> editComment(
      {required String commentId, required String body}) async {
    final data = await _mutate(kEditComment,
        variables: {'commentId': commentId, 'body': body});
    _throwIfPayloadErrors(data['editComment']);
  }

  Future<bool> deleteComment(String commentId) async {
    final data =
        await _mutate(kDeleteComment, variables: {'commentId': commentId});
    return _isSuccess(data['deleteComment']);
  }

  // ---- Poll / award / AI -------------------------------------------------

  Future<CirclePoll?> votePoll(
      {required String pollId, required String optionId}) async {
    final data = await _mutate(kVotePoll,
        variables: {'pollId': pollId, 'optionId': optionId});
    final payload = asMap(data['votePoll']);
    _throwIfPayloadErrors(payload);
    return CirclePoll.maybe(payload?['poll']);
  }

  Future<void> giveAward(
      {required String postId, required String awardTypeId}) async {
    final data = await _mutate(kGiveAward,
        variables: {'postId': postId, 'awardTypeId': awardTypeId});
    _throwIfPayloadErrors(data['giveAward']);
  }

  /// Asks the AI to reply on a post; returns the generated comment body.
  Future<String?> askAiOnPost(String postId) async {
    final data = await _mutate(kAskAiOnPost, variables: {'postId': postId});
    final payload = asMap(data['askAiOnPost']);
    _throwIfPayloadErrors(payload);
    return asStringOrNull(asMap(payload?['comment'])?['body']);
  }
}
