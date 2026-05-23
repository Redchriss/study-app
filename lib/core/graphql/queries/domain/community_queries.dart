// ─── Community / GraphQL queries & mutations ──────────────────────────────
// Replaces old circle_queries.dart. Maps 1:1 to the new backend schema.

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
    id text description
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

const String kCommunityPosts = r'''
query CommunityPosts(
  $slug: String!, $sort: PostSortEnum, $timeFilter: TimeFilterEnum,
  $postType: PostTypeEnum, $flairId: ID, $limit: Int, $after: String
) {
  communityPosts(
    slug: $slug, sort: $sort, timeFilter: $timeFilter,
    postType: $postType, flairId: $flairId, limit: $limit, after: $after
  ) {
    edges { cursor node { ...PostFields } }
    pageInfo { hasNextPage endCursor }
    totalCount
  }
}
''';

const String kPost = r'''
query Post($communitySlug: String!, $postSlug: String!) {
  post(communitySlug: $communitySlug, postSlug: $postSlug) {
    ...PostFields
    bodyHtml
    isPinned isLocked isRemoved isDeleted isEdited
    url urlDomain urlThumbnail
    videoUrl videoDuration
    isOc isSpoiler
    flairText
    awardCount
    editedAt
    community { id name slug displayName icon }
    poll {
      id closesAt allowAddOption
      options { id text order voteCount }
      userVote { id text }
    }
    galleryItems { id imageUrl caption linkUrl order }
    crosspostInfo { id title slug author { username } community { slug } }
  }
}
''';

const String kPostById = r'''
query PostById($id: ID!) {
  postById(id: $id) {
    ...PostFields
    community { id name slug }
  }
}
''';

const String kPostComments = r'''
query PostComments($postId: ID!, $sort: CommentSortEnum, $limit: Int, $after: String) {
  postComments(postId: $postId, sort: $sort, limit: $limit, after: $after) {
    edges { cursor node { ...CommentFields } }
    pageInfo { hasNextPage endCursor }
    totalCount
  }
}
''';

const String kHomeFeed = r'''
query HomeFeed($sort: HomeFeedSortEnum, $limit: Int, $after: String) {
  homeFeed(sort: $sort, limit: $limit, after: $after) {
    edges { cursor node { ...PostFields } }
    pageInfo { hasNextPage endCursor }
    totalCount
  }
}
''';

const String kPopularPosts = r'''
query PopularPosts($limit: Int, $after: String) {
  popularPosts(limit: $limit, after: $after) {
    edges { cursor node { ...PostFields } }
    pageInfo { hasNextPage endCursor }
    totalCount
  }
}
''';

const String kSavedPosts = r'''
query SavedPosts($limit: Int, $after: String) {
  savedPosts(limit: $limit, after: $after) {
    edges { cursor node { ...PostFields } }
    pageInfo { hasNextPage endCursor }
    totalCount
  }
}
''';

const String kUserProfile = r'''
query UserProfile($username: String!) {
  userProfile(username: $username) {
    user { id username }
    avatarUrl bannerUrl bio
    postKarma commentKarma awardKarma totalKarma
    createdAt
  }
}
''';

const String kMyProfile = r'''
query MyProfile {
  myProfile {
    user { id username }
    avatarUrl bannerUrl bio
    postKarma commentKarma awardKarma totalKarma
    createdAt
  }
}
''';

const String kUserPosts = r'''
query UserPosts($username: String!, $sort: PostSortEnum, $limit: Int, $after: String) {
  userPosts(username: $username, sort: $sort, limit: $limit, after: $after) {
    edges { cursor node { ...PostFields } }
    pageInfo { hasNextPage endCursor }
    totalCount
  }
}
''';

const String kUserComments = r'''
query UserComments($username: String!, $sort: CommentSortEnum, $limit: Int, $after: String) {
  userComments(username: $username, sort: $sort, limit: $limit, after: $after) {
    edges { cursor node { ...CommentFields } }
    pageInfo { hasNextPage endCursor }
    totalCount
  }
}
''';

const String kSearchPosts = r'''
query SearchPosts(
  $query: String!, $communitySlug: String, $sort: SearchSortEnum,
  $postType: PostTypeEnum, $timeFilter: TimeFilterEnum,
  $limit: Int, $after: String
) {
  searchPosts(
    query: $query, communitySlug: $communitySlug, sort: $sort,
    postType: $postType, timeFilter: $timeFilter,
    limit: $limit, after: $after
  ) {
    edges { cursor node { ...PostFields } }
    pageInfo { hasNextPage endCursor }
    totalCount
  }
}
''';

// ─── Fragments ─────────────────────────────────────────────────────────────

const String kPostFields = r'''
fragment PostFields on PostType {
  id title slug body postType
  imageUrl
  upvoteCount downvoteCount score commentCount
  fuzzedUpvotes fuzzedDownvotes fuzzedScore
  isOc isSpoiler isPinned isLocked
  author { id username }
  community { id name slug displayName icon }
  flairText
  createdAt
}
''';

const String kCommentFields = r'''
fragment CommentFields on CommentType {
  id body bodyHtml
  upvoteCount downvoteCount score
  fuzzedUpvotes fuzzedDownvotes fuzzedScore
  isDeleted isEdited isPinned isAnswer isCollapsed
  depth
  author { id username }
  repliesCount
  createdAt editedAt
}
''';

// ─── Mutations ─────────────────────────────────────────────────────────────

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
mutation UpdateCommunity($slug: String!, $description: String, $sidebar: String) {
  updateCommunity(slug: $slug, description: $description, sidebar: $sidebar) {
    community { id slug }
    errors
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

const String kCreatePost = r'''
mutation CreatePost(
  $communitySlug: String!, $title: String!, $body: String,
  $postType: PostTypeEnum!, $url: String, $imageBase64: String,
  $videoBase64: String, $flairId: ID, $isOc: Boolean, $isSpoiler: Boolean,
  $pollOptions: [String], $pollDurationHours: Int
) {
  createPost(
    communitySlug: $communitySlug, title: $title, body: $body,
    postType: $postType, url: $url, imageBase64: $imageBase64,
    videoBase64: $videoBase64, flairId: $flairId,
    isOc: $isOc, isSpoiler: $isSpoiler,
    pollOptions: $pollOptions, pollDurationHours: $pollDurationHours
  ) {
    post { id slug }
    errors
  }
}
''';

const String kEditPost = r'''
mutation EditPost($postId: ID!, $title: String, $body: String) {
  editPost(postId: $postId, title: $title, body: $body) {
    post { id slug title body }
    errors
  }
}
''';

const String kDeletePost = r'''
mutation DeletePost($postId: ID!) {
  deletePost(postId: $postId) { success }
}
''';

const String kVotePost = r'''
mutation VotePost($postId: ID!, $direction: Int!) {
  votePost(postId: $postId, direction: $direction) {
    post { id fuzzedUpvotes fuzzedDownvotes fuzzedScore }
    errors
  }
}
''';

const String kSavePost = r'''
mutation SavePost($postId: ID!) {
  savePost(postId: $postId) { success }
}
''';

const String kUnsavePost = r'''
mutation UnsavePost($postId: ID!) {
  unsavePost(postId: $postId) { success }
}
''';

const String kAddComment = r'''
mutation AddComment($postId: ID!, $body: String!, $parentId: ID) {
  addComment(postId: $postId, body: $body, parentId: $parentId) {
    comment { id body author { id username } createdAt }
    errors
  }
}
''';

const String kEditComment = r'''
mutation EditComment($commentId: ID!, $body: String!) {
  editComment(commentId: $commentId, body: $body) {
    comment { id body }
    errors
  }
}
''';

const String kDeleteComment = r'''
mutation DeleteComment($commentId: ID!) {
  deleteComment(commentId: $commentId) { success }
}
''';

const String kVoteComment = r'''
mutation VoteComment($commentId: ID!, $direction: Int!) {
  voteComment(commentId: $commentId, direction: $direction) {
    comment { id fuzzedUpvotes fuzzedDownvotes fuzzedScore }
    errors
  }
}
''';

const String kSaveComment = r'''
mutation SaveComment($commentId: ID!) {
  saveComment(commentId: $commentId) { success }
}
''';

const String kReportPost = r'''
mutation ReportPost($postId: ID!, $reason: String!) {
  reportPost(postId: $postId, reason: $reason) { success }
}
''';

const String kReportComment = r'''
mutation ReportComment($commentId: ID!, $reason: String!) {
  reportComment(commentId: $commentId, reason: $reason) { success }
}
''';

const String kFollowUser = r'''
mutation FollowUser($username: String!) {
  followUser(username: $username) { success }
}
''';

const String kUnfollowUser = r'''
mutation UnfollowUser($username: String!) {
  unfollowUser(username: $username) { success }
}
''';

const String kBlockUser = r'''
mutation BlockUser($username: String!) {
  blockUser(username: $username) { success }
}
''';

const String kUnblockUser = r'''
mutation UnblockUser($username: String!) {
  unblockUser(username: $username) { success }
}
''';

const String kMarkOc = r'''
mutation MarkOc($postId: ID!) {
  markOc(postId: $postId) { success }
}
''';

const String kMarkSpoiler = r'''
mutation MarkSpoiler($postId: ID!) {
  markSpoiler(postId: $postId) { success }
}
''';

const String kAddRule = r'''
mutation AddRule($communitySlug: String!, $text: String!, $description: String) {
  addRule(communitySlug: $communitySlug, text: $text, description: $description) {
    communityRule { id text }
    errors
  }
}
''';

const String kAddModerator = r'''
mutation AddModerator($slug: String!, $username: String!) {
  addModerator(slug: $slug, username: $username) {
    membership { id role user { username } }
    errors
  }
}
''';

const String kRemoveModerator = r'''
mutation RemoveModerator($slug: String!, $username: String!) {
  removeModerator(slug: $slug, username: $username) { success }
}
''';

const String kRemovePost = r'''
mutation RemovePost($postId: ID!) {
  removePost(postId: $postId) { success }
}
''';

const String kApprovePost = r'''
mutation ApprovePost($postId: ID!) {
  approvePost(postId: $postId) { success }
}
''';

const String kPinPost = r'''
mutation PinPost($postId: ID!) {
  pinPost(postId: $postId) { success }
}
''';

const String kLockPost = r'''
mutation LockPost($postId: ID!) {
  lockPost(postId: $postId) { success }
}
''';

const String kBanUser = r'''
mutation BanUser($communitySlug: String!, $username: String!, $reason: String) {
  banUser(communitySlug: $communitySlug, username: $username, reason: $reason) {
    membership { id isBanned }
    errors
  }
}
''';

const String kUnbanUser = r'''
mutation UnbanUser($communitySlug: String!, $username: String!) {
  unbanUser(communitySlug: $communitySlug, username: $username) { success }
}
''';

const String kMuteUser = r'''
mutation MuteUser($communitySlug: String!, $username: String!, $durationHours: Int) {
  muteUser(communitySlug: $communitySlug, username: $username, durationHours: $durationHours) {
    membership { id }
    errors
  }
}
''';

const String kVotePoll = r'''
mutation VotePoll($pollId: ID!, $optionId: ID!) {
  votePoll(pollId: $pollId, optionId: $optionId) {
    poll { id options { id text voteCount } voteCount }
    errors
  }
}
''';

const String kGiveAward = r'''
mutation GiveAward($postId: ID!, $awardTypeId: ID!) {
  giveAward(postId: $postId, awardTypeId: $awardTypeId) { success errors }
}
''';

const String kReportsQuery = r'''
query Reports($communitySlug: String!, $status: String) {
  reports(communitySlug: $communitySlug, status: $status) {
    id
    reason
    status
    modNote
    createdAt
    reporter { username }
    reviewedBy { username }
    post { id title slug author { username } }
    comment { id body author { username } }
  }
}
''';

const String kModLogQuery = r'''
query ModLog($communitySlug: String!) {
  modLog(communitySlug: $communitySlug) {
    id
    action
    details
    createdAt
    moderator { username }
    targetUser { username }
    post { id title slug }
  }
}
''';

const String kResolveReport = r'''
mutation ResolveReport($reportId: ID!, $action: String!, $modNote: String) {
  resolveReport(reportId: $reportId, action: $action, modNote: $modNote) {
    id
    status
  }
}
''';
