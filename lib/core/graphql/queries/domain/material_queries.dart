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

const String kUploadMaterial = r'''
mutation UploadMaterial($title: String!, $subjectId: ID!, $contentType: String!, $description: String, $contentText: String, $youtubeUrl: String) {
  uploadMaterial(title: $title, subjectId: $subjectId, contentType: $contentType, description: $description, contentText: $contentText, youtubeUrl: $youtubeUrl) {
    success errors
    material { id title slug }
  }
}
''';

const String kSubjects = r'''
query Subjects($educationLevel: String) {
  subjects(educationLevel: $educationLevel) { id name }
}
''';

const String kMyUploadedMaterials = r'''
query MyUploadedMaterials($limit: Int, $offset: Int) {
  myUploadedMaterials(limit: $limit, offset: $offset) {
    id
    title
    slug
    contentType
    isApproved
    subject { id name }
    createdAt
  }
}
''';

const String kDeleteMyMaterial = r'''
mutation DeleteMyMaterial($slug: String!) {
  deleteMyMaterial(slug: $slug) {
    success
    errors
  }
}
''';
