part of 'circles_repository.dart';

/// Newly-reachable community actions (Step 2 gap-fill): comment moderation,
/// mark-answer / collapse, approved-users, flair management, and community
/// icon/banner uploads. Backed by ops that previously had no app constant.
extension CirclesRepositoryFlairActions on CirclesRepository {
  // ---- Flair reads -------------------------------------------------------

  /// Returns the post-flair templates configured for [slug].
  Future<List<CirclePostFlair>> communityFlairs(String slug) async {
    final data = await _query(kCommunityFlairs, variables: {'slug': slug});
    return asMapList(data['communityFlair'])
        .map(CirclePostFlair.fromJson)
        .toList();
  }

  // ---- Comment moderation ------------------------------------------------

  Future<void> approveComment(String commentId) async {
    final data =
        await _mutate(kApproveComment, variables: {'commentId': commentId});
    _throwIfPayloadErrors(data['approveComment']);
  }

  Future<void> pinComment(String commentId) async {
    final data = await _mutate(kPinComment, variables: {'commentId': commentId});
    _throwIfPayloadErrors(data['pinComment']);
  }

  Future<void> distinguishComment(String commentId) async {
    final data =
        await _mutate(kDistinguishComment, variables: {'commentId': commentId});
    _throwIfPayloadErrors(data['distinguishComment']);
  }

  /// Marks [commentId] as the accepted answer for [postId] (post author only).
  Future<void> markAnswer(
      {required String commentId, required String postId}) async {
    final data = await _mutate(kMarkAnswer,
        variables: {'commentId': commentId, 'postId': postId});
    _throwIfPayloadErrors(data['markAnswer']);
  }

  Future<bool> collapseComment(String commentId) async {
    final data =
        await _mutate(kCollapseComment, variables: {'commentId': commentId});
    return _isSuccess(data['collapseComment']);
  }

  // ---- Approved users ----------------------------------------------------

  Future<bool> addApprovedUser(
      {required String communitySlug, required String username}) async {
    final data = await _mutate(kAddApprovedUser,
        variables: {'communitySlug': communitySlug, 'username': username});
    return _isSuccess(data['addApprovedUser']);
  }

  Future<bool> removeApprovedUser(
      {required String communitySlug, required String username}) async {
    final data = await _mutate(kRemoveApprovedUser,
        variables: {'communitySlug': communitySlug, 'username': username});
    return _isSuccess(data['removeApprovedUser']);
  }

  // ---- Flair management --------------------------------------------------

  Future<CirclePostFlair?> createPostFlair({
    required String slug,
    required String text,
    String? color,
    String? textColor,
    String? emoji,
    bool? modOnly,
  }) async {
    final data = await _mutate(kCreatePostFlair, variables: {
      'slug': slug,
      'text': text,
      'color': color,
      'textColor': textColor,
      'emoji': emoji,
      'modOnly': modOnly,
    });
    return CirclePostFlair.maybe(data['createPostFlair']);
  }

  Future<CirclePostFlair?> updatePostFlair({
    required String flairId,
    String? text,
    String? color,
  }) async {
    final data = await _mutate(kUpdatePostFlair,
        variables: {'flairId': flairId, 'text': text, 'color': color});
    return CirclePostFlair.maybe(data['updatePostFlair']);
  }

  Future<bool> deletePostFlair(String flairId) async {
    final data =
        await _mutate(kDeletePostFlair, variables: {'flairId': flairId});
    return _isSuccess(data['deletePostFlair']);
  }

  Future<CircleUserFlair?> setUserFlair({
    required String slug,
    String? text,
    String? emoji,
  }) async {
    final data = await _mutate(kSetUserFlair,
        variables: {'slug': slug, 'text': text, 'emoji': emoji});
    return CircleUserFlair.maybe(data['setUserFlair']);
  }

  /// Assigns a flair to a post (template [flairId] and/or [customText]).
  Future<void> setPostFlair({
    required String postId,
    String? flairId,
    String? customText,
  }) async {
    final data = await _mutate(kSetPostFlair, variables: {
      'postId': postId,
      'flairId': flairId,
      'customText': customText,
    });
    _throwIfPayloadErrors(data['setPostFlair']);
  }

  // ---- Community image uploads ------------------------------------------

  Future<String?> uploadCommunityIcon({
    required String slug,
    required String imageBase64,
  }) async {
    final data = await _mutate(kUploadCommunityIcon,
        variables: {'slug': slug, 'imageBase64': imageBase64});
    final payload = asMap(data['uploadCommunityIcon']);
    _throwIfPayloadErrors(payload);
    return asStringOrNull(asMap(payload?['community'])?['icon']);
  }

  Future<String?> uploadCommunityBanner({
    required String slug,
    required String imageBase64,
  }) async {
    final data = await _mutate(kUploadCommunityBanner,
        variables: {'slug': slug, 'imageBase64': imageBase64});
    final payload = asMap(data['uploadCommunityBanner']);
    _throwIfPayloadErrors(payload);
    return asStringOrNull(asMap(payload?['community'])?['banner']);
  }
}
