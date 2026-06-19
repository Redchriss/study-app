// Flair management ops — previously unreachable from the app.
// Backed by `apps/communities/schema/rules_mutations.py` (flairs / user flair)
// and `post_actions.py` (`SetPostFlair`).

const String kCreatePostFlair = r'''
mutation CreatePostFlair(
  $slug: String!, $text: String!, $color: String,
  $textColor: String, $emoji: String, $modOnly: Boolean
) {
  createPostFlair(
    slug: $slug, text: $text, color: $color,
    textColor: $textColor, emoji: $emoji, modOnly: $modOnly
  ) {
    id text color textColor emoji modOnly order
  }
}
''';

const String kUpdatePostFlair = r'''
mutation UpdatePostFlair($flairId: ID!, $text: String, $color: String) {
  updatePostFlair(flairId: $flairId, text: $text, color: $color) {
    id text color textColor emoji modOnly order
  }
}
''';

const String kDeletePostFlair = r'''
mutation DeletePostFlair($flairId: ID!) {
  deletePostFlair(flairId: $flairId) { success }
}
''';

const String kSetUserFlair = r'''
mutation SetUserFlair($slug: String!, $text: String, $emoji: String) {
  setUserFlair(slug: $slug, text: $text, emoji: $emoji) {
    id text emoji
  }
}
''';

const String kSetPostFlair = r'''
mutation SetPostFlair($postId: ID!, $flairId: ID, $customText: String) {
  setPostFlair(postId: $postId, flairId: $flairId, customText: $customText) {
    post { id flairText }
    errors
  }
}
''';
