const String kCommunity = r'''
query Community($slug: String!) {
  community(slug: $slug) {
    id name slug displayName description sidebarMarkdown
    icon banner memberCount postCount
    communityType over18
    allowImages allowVideos allowPolls allowLinks allowGalleries allowCrossposts
    spoilersEnabled
    isMember isModerator isFavorite userRole
    createdAt
    createdBy { id username }
  }
  communityFlair(slug: $slug) {
    id text backgroundColor textColor
  }
}
''';

const String kCommunities = r'''
query Communities($search: String, $sort: CommunitySortEnum, $limit: Int, $offset: Int) {
  communities(search: $search, sort: $sort, limit: $limit, offset: $offset) {
    id name slug displayName description icon memberCount postCount communityType
  }
}
''';

const String kMyCommunities = r'''
query MyCommunities {
  myCommunities {
    id name slug displayName icon memberCount
    isFavorite
  }
}
''';

const String kTrendingCommunities = r'''
query TrendingCommunities($limit: Int) {
  trendingCommunities(limit: $limit) {
    id name slug displayName description icon memberCount postCount
  }
}
''';

const String kSuggestedCommunities = r'''
query SuggestedCommunities($limit: Int) {
  suggestedCommunities(limit: $limit) {
    id name slug displayName description icon memberCount
  }
}
''';

const String kCommunityModerators = r'''
query CommunityModerators($slug: String!) {
  communityModerators(slug: $slug) {
    id role
    user { id username }
  }
}
''';

const String kCommunityRules = r'''
query CommunityRules($slug: String!) {
  communityRules(slug: $slug) {
    id title description order
  }
}
''';

const String kCommunityFlairs = r'''
query CommunityFlairs($slug: String!) {
  communityFlair(slug: $slug) {
    id text backgroundColor textColor
  }
}
''';

const String kCreateCommunity = r'''
mutation CreateCommunity(
  $name: String!, $displayName: String!, $description: String,
  $communityType: CommunityTypeEnum, $over18: Boolean
) {
  createCommunity(
    name: $name, displayName: $displayName,
    description: $description, communityType: $communityType, over18: $over18
  ) {
    community { id slug name displayName }
    errors
  }
}
''';

const String kUpdateCommunity = r'''
mutation UpdateCommunity(
  $slug: String!, $description: String, $sidebar: String,
  $communityType: CommunityTypeEnum, $allowImages: Boolean, $allowVideos: Boolean,
  $allowPolls: Boolean, $allowLinks: Boolean, $allowGalleries: Boolean,
  $allowCrossposts: Boolean, $minAccountAgeDays: Int, $minKarmaToPost: Int,
  $spoilersEnabled: Boolean, $over18: Boolean,
) {
  updateCommunity(
    slug: $slug, description: $description, sidebar: $sidebar,
    communityType: $communityType, allowImages: $allowImages, allowVideos: $allowVideos,
    allowPolls: $allowPolls, allowLinks: $allowLinks, allowGalleries: $allowGalleries,
    allowCrossposts: $allowCrossposts, minAccountAgeDays: $minAccountAgeDays,
    minKarmaToPost: $minKarmaToPost, spoilersEnabled: $spoilersEnabled, over18: $over18
  ) {
    community { id slug name displayName description sidebar bannerColor communityType allowImages allowVideos allowPolls allowLinks allowGalleries allowCrossposts minAccountAgeDays minKarmaToPost spoilersEnabled over18 }
    errors
  }
}
''';

const String kCommunityStats = r'''
query CommunityStats($communitySlug: String!) {
  communityStats(communitySlug: $communitySlug) {
    totalMembers newMembersToday postsToday commentsToday activeUsersToday
    topPostThisWeek { id title slug score }
    memberGrowthLast30Days { date count }
    topFlairs { text count }
  }
}
''';

const String kJoinCommunity = r'''
mutation JoinCommunity($slug: String!) {
  joinCommunity(slug: $slug) {
    membership { id role isApproved isBanned isFavorite }
    errors
  }
}
''';

const String kLeaveCommunity = r'''
mutation LeaveCommunity($slug: String!) {
  leaveCommunity(slug: $slug) { success }
}
''';

const String kToggleFavourite = r'''
mutation ToggleFavourite($slug: String!) {
  toggleFavourite(slug: $slug) {
    membership { id isFavorite }
    errors
  }
}
''';
