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
