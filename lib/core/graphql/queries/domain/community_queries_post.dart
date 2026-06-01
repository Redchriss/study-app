const String kCirclePosts = r'''
query CirclePosts($circleSlug: String!, $sort: String, $postType: String, $solvedOnly: Boolean, $offset: Int) {
  circlePosts(circleSlug: $circleSlug, sort: $sort, postType: $postType, solvedOnly: $solvedOnly, offset: $offset) {
    id title slug content createdAt upvoteCount downvoteCount
    author { id username }
  }
}
''';

const String kCirclePost = r'''
query CirclePost($circleSlug: String!, $postSlug: String!) {
  circlePost(circleSlug: $circleSlug, postSlug: $postSlug) {
    id title slug content createdAt upvoteCount downvoteCount
    author { id username }
  }
}
''';

const String kPostComments = r'''
query PostComments($postId: ID!, $sort: String, $limit: Int, $after: String) {
  postComments(postId: $postId, sort: $sort, limit: $limit, after: $after) {
    id body
    author { id username }
    createdAt
  }
}
''';

const String kSearchPosts = r'''
query SearchPosts($query: String!, $circleSlug: String) {
  searchPosts(query: $query, circleSlug: $circleSlug) {
    id title slug createdAt upvoteCount downvoteCount
    author { id username }
  }
}
''';

const String kCreatePost = r'''
mutation CreatePost($circleSlug: String!, $title: String!, $content: String, $postType: String, $solved: Boolean, $image: String, $document: String) {
  createPost(circleSlug: $circleSlug, title: $title, content: $content, postType: $postType, solved: $solved, image: $image, document: $document) {
    post { id slug }
    errors
  }
}
''';

const String kPost = r'''query Post($communitySlug: String!, $postSlug: String!) { __typename }''';
const String kPostById = r'''query PostById($id: ID!) { __typename }''';
const String kHomeFeed = r'''query HomeFeed { __typename }''';
const String kPopularPosts = r'''query PopularPosts { __typename }''';
const String kSavedPosts = r'''query SavedPosts { __typename }''';
const String kUserProfile = r'''query UserProfile($username: String!) { __typename }''';
const String kMyProfile = r'''query MyProfile { __typename }''';
const String kUserPosts = r'''query UserPosts { __typename }''';
const String kUserComments = r'''query UserComments { __typename }''';
const String kCrosspost = r'''mutation Crosspost { __typename }''';
const String kEditPost = r'''mutation EditPost { __typename }''';
const String kDeletePost = r'''mutation DeletePost { __typename }''';
