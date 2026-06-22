part of 'circles_repository.dart';

/// Community membership, social graph, and moderation mutations + the
/// moderation-only list queries (reports, banned/muted/approved members).
extension CirclesRepositoryModActions on CirclesRepository {
  // ---- Community membership ---------------------------------------------

  Future<String> createCommunity({
    required String name,
    required String displayName,
    String? description,
    String? communityType,
    bool? over18,
  }) async {
    final data = await _mutate(kCreateCommunity, variables: {
      'name': name,
      'displayName': displayName,
      'description': description,
      'communityType': communityType,
      'over18': over18,
    });
    final payload = asMap(data['createCommunity']);
    _throwIfPayloadErrors(payload);
    return asString(asMap(payload?['community'])?['slug']);
  }

  Future<void> updateCommunity({
    required String slug,
    Map<String, dynamic> changes = const {},
  }) async {
    final data =
        await _mutate(kUpdateCommunity, variables: {'slug': slug, ...changes});
    _throwIfPayloadErrors(data['updateCommunity']);
  }

  Future<void> joinCommunity(String slug) async {
    final data = await _mutate(kJoinCommunity, variables: {'slug': slug});
    _throwIfPayloadErrors(data['joinCommunity']);
  }

  Future<bool> leaveCommunity(String slug) async {
    final data = await _mutate(kLeaveCommunity, variables: {'slug': slug});
    return _isSuccess(data['leaveCommunity']);
  }

  Future<bool> toggleFavourite(String slug) async {
    final data = await _mutate(kToggleFavourite, variables: {'slug': slug});
    final payload = asMap(data['toggleFavourite']);
    _throwIfPayloadErrors(payload);
    return asBool(asMap(payload?['membership'])?['isFavorite']);
  }

  // ---- Social graph ------------------------------------------------------

  Future<bool> reportPost(
      {required String postId, required String reason}) async {
    final data = await _mutate(kReportPost,
        variables: {'postId': postId, 'reason': reason});
    return _isSuccess(data['reportPost']);
  }

  Future<bool> reportComment(
      {required String commentId, required String reason}) async {
    final data = await _mutate(kReportComment,
        variables: {'commentId': commentId, 'reason': reason});
    return _isSuccess(data['reportComment']);
  }

  Future<bool> followUser(String username) async {
    final data = await _mutate(kFollowUser, variables: {'username': username});
    return _isSuccess(data['followUser']);
  }

  Future<bool> unfollowUser(String username) async {
    final data =
        await _mutate(kUnfollowUser, variables: {'username': username});
    return _isSuccess(data['unfollowUser']);
  }

  Future<bool> blockUser(String username) async {
    final data = await _mutate(kBlockUser, variables: {'username': username});
    return _isSuccess(data['blockUser']);
  }

  Future<bool> unblockUser(String username) async {
    final data = await _mutate(kUnblockUser, variables: {'username': username});
    return _isSuccess(data['unblockUser']);
  }

  // ---- Moderation: posts -------------------------------------------------

  Future<bool> removePost(String postId) async {
    final data = await _mutate(kRemovePost, variables: {'postId': postId});
    final payload = asMap(data['removePost']);
    _throwIfPayloadErrors(payload);
    return asMap(payload?['post']) != null;
  }

  Future<bool> approvePost(String postId) async {
    final data = await _mutate(kApprovePost, variables: {'postId': postId});
    final payload = asMap(data['approvePost']);
    _throwIfPayloadErrors(payload);
    return asMap(payload?['post']) != null;
  }

  Future<void> pinPost({required String postId, required bool pinned}) async {
    final data = await _mutate(kPinPost,
        variables: {'postId': postId, 'pinned': pinned});
    _throwIfPayloadErrors(data['pinPost']);
  }

  Future<void> lockPost({required String postId, required bool locked}) async {
    final data = await _mutate(kLockPost,
        variables: {'postId': postId, 'locked': locked});
    _throwIfPayloadErrors(data['lockPost']);
  }

  Future<void> distinguishPost(String postId) async {
    final data = await _mutate(kDistinguishPost, variables: {'postId': postId});
    _throwIfPayloadErrors(data['distinguishPost']);
  }

  Future<bool> markOc(String postId) async {
    final data = await _mutate(kMarkOc, variables: {'postId': postId});
    final payload = asMap(data['markOc']);
    _throwIfPayloadErrors(payload);
    return asMap(payload?['post']) != null;
  }

  Future<bool> markSpoiler(
      {required String postId, required bool isSpoiler}) async {
    final data = await _mutate(kMarkSpoiler,
        variables: {'postId': postId, 'isSpoiler': isSpoiler});
    final payload = asMap(data['markSpoiler']);
    _throwIfPayloadErrors(payload);
    return asMap(payload?['post']) != null;
  }

  // ---- Moderation: users -------------------------------------------------

  Future<void> banUser({
    required String communitySlug,
    required String username,
    required String reason,
    bool? isPermanent,
    int? durationDays,
    String? modNote,
  }) async {
    final data = await _mutate(kBanUser, variables: {
      'communitySlug': communitySlug,
      'username': username,
      'reason': reason,
      'isPermanent': isPermanent,
      'durationDays': durationDays,
      'modNote': modNote,
    });
    _throwIfPayloadErrors(data['banUser']);
  }

  Future<bool> unbanUser(
      {required String communitySlug, required String username}) async {
    final data = await _mutate(kUnbanUser,
        variables: {'communitySlug': communitySlug, 'username': username});
    return _isSuccess(data['unbanUser']);
  }

  Future<void> muteUser({
    required String communitySlug,
    required String username,
    required int durationDays,
    String? modNote,
  }) async {
    final data = await _mutate(kMuteUser, variables: {
      'communitySlug': communitySlug,
      'username': username,
      'durationDays': durationDays,
      'modNote': modNote,
    });
    _throwIfPayloadErrors(data['muteUser']);
  }

  Future<bool> unmuteUser(
      {required String communitySlug, required String username}) async {
    final data = await _mutate(kUnmuteUser,
        variables: {'communitySlug': communitySlug, 'username': username});
    return _isSuccess(data['unmuteUser']);
  }

  // ---- Moderation: rules, mods, reports ---------------------------------

  Future<String?> resolveReport({
    required String reportId,
    required String action,
    String? modNote,
  }) async {
    final data = await _mutate(kResolveReport, variables: {
      'reportId': reportId,
      'action': action,
      'modNote': modNote,
    });
    return asStringOrNull(asMap(data['resolveReport'])?['status']);
  }

  Future<CircleRule?> addRule({
    required String slug,
    required String title,
    String? description,
  }) async {
    final data = await _mutate(kAddRule, variables: {
      'slug': slug,
      'title': title,
      'description': description,
    });
    final rule = asMap(data['addRule']);
    return rule == null ? null : CircleRule.fromJson(rule);
  }

  Future<bool> deleteRule(String ruleId) async {
    final data = await _mutate(kDeleteRule, variables: {'ruleId': ruleId});
    return _isSuccess(data['deleteRule']);
  }

  // ---- Moderation: list queries -----------------------------------------

  Future<List<Map<String, dynamic>>> reports(
      {required String communitySlug, String? status}) async {
    final data = await _query(kReportsQuery,
        variables: {'communitySlug': communitySlug, 'status': status});
    return asMapList(data['reports']);
  }

  Future<List<Map<String, dynamic>>> bannedMembers(String slug) async {
    final data = await _query(kBannedMembers, variables: {'slug': slug});
    return asMapList(data['bannedMembers']);
  }

  Future<List<Map<String, dynamic>>> approvedUsers(String slug) async {
    final data = await _query(kApprovedUsers, variables: {'slug': slug});
    return asMapList(data['approvedUsers']);
  }
}
