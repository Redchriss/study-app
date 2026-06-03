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
