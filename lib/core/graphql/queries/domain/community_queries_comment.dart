const String kAddComment = r'''
mutation AddComment($postId: ID!, $body: String!, $parentId: ID) {
  addComment(postId: $postId, body: $body, parentId: $parentId) {
    id body
    author { id username }
    createdAt
  }
}
''';
