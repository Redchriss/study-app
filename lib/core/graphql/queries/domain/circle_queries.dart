const String kStudyCircles = r'''
query StudyCircles($level: String, $search: String) {
  studyCircles(educationLevel: $level, search: $search) {
    id name slug description memberCount educationLevel
    isMember isFavorite
  }
}
''';

const String kMyCircles = r'''
query MyCircles {
  myCircles {
    id name slug memberCount educationLevel
  }
}
''';

const String kCirclePosts = r'''
query CirclePosts($slug: String!, $sort: String, $offset: Int) {
  circlePosts(circleSlug: $slug, sort: $sort, offset: $offset) {
    id title slug body upvoteCount downvoteCount commentCount postType isSolved isPinned score imageUrl
    author { username }
    createdAt
  }
}
''';

const String kCircleDetail = r'''
query CircleDetail($slug: String!) {
  studyCircle(slug: $slug) { id name description memberCount isMember isFavorite educationLevel }
}
''';

const String kPostDetail = r'''
query PostDetail($circleSlug: String!, $postSlug: String!) {
  circlePost(circleSlug: $circleSlug, postSlug: $postSlug) {
    id title body upvoteCount downvoteCount commentCount postType isSolved score userVote imageUrl
    author { username } createdAt
  }
}
''';

const String kSearchPosts = r'''
query SearchPosts($query: String!, $circleSlug: String) {
  searchPosts(query: $query, circleSlug: $circleSlug) {
    id title slug body upvoteCount commentCount postType score
    author { username }
    createdAt
  }
}
''';

const String kPostComments = r'''
query PostComments($postId: ID!) {
  postComments(postId: $postId) {
    id body upvoteCount isAnswer createdAt
    author { username }
    replies { id body upvoteCount createdAt author { username } }
  }
}
''';

const String kJoinCircle = r'''
mutation JoinCircle($slug: String!) {
  joinCircle(circleSlug: $slug) {
    success
    circle { id name slug memberCount isMember isFavorite educationLevel }
  }
}
''';

const String kCreatePost = r'''
mutation CreatePost($circleSlug: String!, $title: String!, $content: String!, $postType: String, $imageBase64: String) {
  createPost(circleSlug: $circleSlug, title: $title, content: $content, postType: $postType, imageBase64: $imageBase64) {
    success errors
    post { id slug title imageUrl }
  }
}
''';

const String kAddComment = r'''
mutation AddComment($postId: ID!, $content: String!, $parentId: ID) {
  addComment(postId: $postId, content: $content, parentId: $parentId) {
    success errors
    comment { id body author { username } createdAt }
  }
}
''';

const String kVotePost = r'''
mutation VotePost($postId: ID!, $direction: String!) {
  votePost(postId: $postId, direction: $direction) { success }
}
''';

const String kAskAiOnPost = r'''
mutation AskAiOnPost($postId: ID!) {
  askAiOnPost(postId: $postId) { success comment { id body } }
}
''';

const String kToggleFavouriteCircle = r'''
mutation ToggleFavouriteCircle($circleSlug: String!) {
  toggleFavouriteCircle(circleSlug: $circleSlug) { success }
}
''';

const String kMarkAnswer = r'''
mutation MarkAnswer($commentId: ID!, $postId: ID!) {
  markAnswer(commentId: $commentId, postId: $postId) { success }
}
''';
