const String kPostFields = r'''
fragment PostFields on PostType {
  id title slug body postType
  imageUrl
  upvoteCount downvoteCount score commentCount
  fuzzedUpvotes fuzzedDownvotes fuzzedScore
  isOc isSpoiler isPinned isLocked isRemoved isDeleted isEdited isNsfw
  shareCount viewCount awardCount
  voteDirection isSaved
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

const String kCommunityPosts = r'''
query CommunityPosts(
  $slug: String!, $sort: PostSortEnum, $timeFilter: TimeFilterEnum,
  $postType: PostTypeEnum, $flairId: ID, $isPinned: Boolean, $limit: Int, $after: String
) {
  communityPosts(
    slug: $slug, sort: $sort, timeFilter: $timeFilter,
    postType: $postType, flairId: $flairId, isPinned: $isPinned, limit: $limit, after: $after
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
    urlTitle urlDescription
    videoUrl videoDuration
    isOc isSpoiler
    flairText flairEmoji flairColor
    isBookmarked awardCount viewCount shareCount
    editedAt
    community { id name slug displayName icon isMember isModerator }
    poll {
      id closesAt allowAddOption voteCount
      options { id text order voteCount }
      userVote { id optionId text }
    }
    galleryItems { id imageUrl caption linkUrl order }
    crosspostInfo { id title slug postType imageUrl author { id username } community { id slug name } }
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

const String kSearch = r'''
fragment SearchPostFields on PostType {
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
query Search(
  $query: String!, $type: SearchTypeEnum, $communitySlug: String,
  $sort: SearchSortEnum, $timeFilter: TimeFilterEnum,
  $limit: Int, $after: String
) {
  search(
    query: $query, type: $type, communitySlug: $communitySlug,
    sort: $sort, timeFilter: $timeFilter,
    limit: $limit, after: $after
  ) {
    posts {
      edges { cursor node { ...SearchPostFields } }
      pageInfo { hasNextPage endCursor }
      totalCount
    }
    communities {
      id name slug displayName description icon banner
      memberCount postCount communityType
    }
    users {
      user { id username }
      avatarUrl bannerUrl bio
      postKarma commentKarma awardKarma totalKarma
    }
  }
}
''';

const String kUserProfile = r'''
query UserProfile($username: String!) {
  userProfile(username: $username) {
    user { id username }
    avatarUrl bannerUrl bio
    postKarma commentKarma awardKarma totalKarma
    isFollowing isBlocked
    achievements {
      id achievement { id name description icon category }
      earnedAt
    }
    activeCommunities {
      slug name displayName icon memberCount
    }
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

const String kCreatePost = r'''
mutation CreatePost(
  $communitySlug: String!, $title: String!, $body: String,
  $postType: PostTypeEnum!, $url: String, $imageBase64: String,
  $videoBase64: String, $galleryItems: [GalleryItemInput],
  $flairId: ID, $isOc: Boolean, $isSpoiler: Boolean,
  $pollOptions: [String], $pollDurationHours: Int
) {
  createPost(
    communitySlug: $communitySlug, title: $title, body: $body,
    postType: $postType, url: $url, imageBase64: $imageBase64,
    videoBase64: $videoBase64, galleryItems: $galleryItems,
    flairId: $flairId,
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

const String kCrosspost = r'''
mutation Crosspost($originalPostId: ID!, $communitySlug: String!, $title: String) {
  crosspost(originalPostId: $originalPostId, communitySlug: $communitySlug, title: $title) {
    post { id slug title }
    errors
  }
}
''';
