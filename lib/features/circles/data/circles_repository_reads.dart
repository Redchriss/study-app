part of 'circles_repository.dart';

/// Read-only community queries returning typed models / pages.
extension CirclesRepositoryReads on CirclesRepository {
  // ---- Feeds -------------------------------------------------------------

  Future<CirclePage<CirclePost>> homeFeed({
    String? sort,
    int limit = 20,
    String? after,
  }) async {
    final data = await _query(kHomeFeed,
        variables: {'sort': sort, 'limit': limit, 'after': after});
    return CirclePage.fromConnection(data['homeFeed'], CirclePost.fromJson);
  }

  Future<CirclePage<CirclePost>> popularPosts({
    int limit = 20,
    String? after,
  }) async {
    final data =
        await _query(kPopularPosts, variables: {'limit': limit, 'after': after});
    return CirclePage.fromConnection(data['popularPosts'], CirclePost.fromJson);
  }

  Future<CirclePage<CirclePost>> savedPosts({
    int limit = 20,
    String? after,
  }) async {
    final data =
        await _query(kSavedPosts, variables: {'limit': limit, 'after': after});
    return CirclePage.fromConnection(data['savedPosts'], CirclePost.fromJson);
  }

  Future<CirclePage<CirclePost>> communityPosts({
    required String slug,
    String? sort,
    String? timeFilter,
    String? postType,
    String? flairId,
    bool? isPinned,
    int limit = 20,
    String? after,
  }) async {
    final data = await _query(kCommunityPosts, variables: {
      'slug': slug,
      'sort': sort,
      'timeFilter': timeFilter,
      'postType': postType,
      'flairId': flairId,
      'isPinned': isPinned,
      'limit': limit,
      'after': after,
    });
    return CirclePage.fromConnection(
        data['communityPosts'], CirclePost.fromJson);
  }

  // ---- Single post & comments -------------------------------------------

  Future<CirclePost?> post({
    required String communitySlug,
    required String postSlug,
  }) async {
    final data = await _query(kPost, variables: {
      'communitySlug': communitySlug,
      'postSlug': postSlug,
    });
    return CirclePost.maybe(data['post']);
  }

  Future<CirclePost?> postById(String id) async {
    final data = await _query(kPostById, variables: {'id': id});
    return CirclePost.maybe(data['postById']);
  }

  Future<CirclePage<CircleComment>> postComments({
    required String postId,
    String? sort,
    int limit = 50,
    String? after,
  }) async {
    final data = await _query(kPostComments, variables: {
      'postId': postId,
      'sort': sort,
      'limit': limit,
      'after': after,
    });
    return CirclePage.fromConnection(
        data['postComments'], CircleComment.fromJson);
  }

  // ---- Communities -------------------------------------------------------

  Future<CircleCommunity?> community(String slug) async {
    final data = await _query(kCommunity, variables: {'slug': slug});
    return data['community'] == null
        ? null
        : CircleCommunity.fromJson(asMap(data['community'])!);
  }

  Future<CirclePage<CircleCommunity>> communities({
    String? search,
    String? sort,
    int limit = 20,
    String? after,
  }) async {
    final data = await _query(kCommunities, variables: {
      'search': search,
      'sort': sort,
      'limit': limit,
      'after': after,
    });
    return CirclePage.fromConnection(
        data['communities'], CircleCommunity.fromJson);
  }

  Future<List<CircleCommunity>> trendingCommunities({int limit = 10}) async {
    final data = await _query(kTrendingCommunities, variables: {'limit': limit});
    return asMapList(data['trendingCommunities'])
        .map(CircleCommunity.fromJson)
        .toList();
  }

  Future<List<CircleRule>> communityRules(String slug) async {
    final data = await _query(kCommunityRules, variables: {'slug': slug});
    return asMapList(data['communityRules']).map(CircleRule.fromJson).toList();
  }

  // ---- Users -------------------------------------------------------------

  Future<CircleUserProfile?> userProfile(String username) async {
    final data = await _query(kUserProfile, variables: {'username': username});
    return data['userProfile'] == null
        ? null
        : CircleUserProfile.fromJson(asMap(data['userProfile'])!);
  }

  Future<CirclePage<CirclePost>> userPosts({
    required String username,
    String? sort,
    int limit = 20,
    String? after,
  }) async {
    final data = await _query(kUserPosts, variables: {
      'username': username,
      'sort': sort,
      'limit': limit,
      'after': after,
    });
    return CirclePage.fromConnection(data['userPosts'], CirclePost.fromJson);
  }

  Future<CirclePage<CircleComment>> userComments({
    required String username,
    String? sort,
    int limit = 20,
    String? after,
  }) async {
    final data = await _query(kUserComments, variables: {
      'username': username,
      'sort': sort,
      'limit': limit,
      'after': after,
    });
    return CirclePage.fromConnection(
        data['userComments'], CircleComment.fromJson);
  }
}
