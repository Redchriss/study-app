const String kMaterials = r'''
query Materials($subjectId: ID, $search: String, $contentType: String, $limit: Int, $offset: Int) {
  materials(subjectId: $subjectId, search: $search, contentType: $contentType, limit: $limit, offset: $offset) {
    id title slug contentType description
    subject { id name }
    createdAt
  }
}
''';

const String kMaterial = r'''
query Material($slug: String!) {
  material(slug: $slug) {
    id
    title
    description
    contentType
    contentText
    youtubeEmbedUrl
    fileUrl
    aiSummary
    isPremium
    isBookmarked
    subject { id name }
    createdAt
  }
}
''';

const String kBookmarkMaterial = r'''
mutation BookmarkMaterial($materialId: ID!) {
  bookmarkMaterial(materialId: $materialId) {
    success
    isBookmarked
  }
}
''';

const String kUnbookmarkMaterial = r'''
mutation UnbookmarkMaterial($materialId: ID!) {
  unbookmarkMaterial(materialId: $materialId) {
    success
    isBookmarked
  }
}
''';

const String kRequestAiTask = r'''
mutation RequestAiTask($materialId: ID!, $taskType: String!) {
  requestAiTask(materialId: $materialId, taskType: $taskType) {
    success
    errors
    creditsCost
    creditsRemaining
  }
}
''';

const String kBookmarkedMaterials = r'''
query BookmarkedMaterials {
  bookmarkedMaterials { id title slug subject { name } contentType }
}
''';
