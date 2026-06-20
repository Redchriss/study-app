const String kMaterials = r'''
query Materials($subjectId: ID, $search: String, $contentType: String, $limit: Int, $offset: Int) {
  materials(subjectId: $subjectId, search: $search, contentType: $contentType, limit: $limit, offset: $offset) {
    id title slug contentType description
    educationLevel viewsCount isPremium isBookmarked aiSummary
    subject { id name }
    createdAt
  }
  latestMaterialProgress {
    currentUnit
    totalUnits
    progressPercent
    lastPositionLabel
    lastOpenedAt
    material {
      slug
      title
      contentType
      subject { name }
    }
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
    youtubeEmbedUrl
    fileUrl
    aiSummary
    aiFlashcardsJson
    studyPack
    isPremium
    isBookmarked
    aiTasks {
      taskType
      status
      statusLabel
      isActive
      errorMessage
    }
    myProgress {
      currentUnit
      totalUnits
      progressPercent
      lastPositionLabel
      lastOpenedAt
    }
    myAnnotations {
      id
      unitIndex
      anchorLabel
      selectedText
      noteText
      color
      updatedAt
    }
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
query Subjects($educationLevel: String!) {
  subjects(educationLevel: $educationLevel) { id name }
}
''';

const String kSuggestMaterialMetadata = r'''
mutation SuggestMaterialMetadata($contentSlice: String, $fileB64: String, $mime: String) {
  suggestMaterialMetadata(contentSlice: $contentSlice, fileB64: $fileB64, mime: $mime) {
    success
    errors
    creditsRemaining
    suggestion {
      title
      subjectId
      contentType
      confidence
    }
  }
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

const String kTrackMaterialProgress = r'''
mutation TrackMaterialProgress($materialSlug: String!, $currentUnit: Int!, $totalUnits: Int!, $lastPositionLabel: String) {
  trackMaterialProgress(
    materialSlug: $materialSlug
    currentUnit: $currentUnit
    totalUnits: $totalUnits
    lastPositionLabel: $lastPositionLabel
  ) {
    success
    errors
    progress {
      currentUnit
      totalUnits
      progressPercent
      lastPositionLabel
      lastOpenedAt
    }
  }
}
''';

const String kSaveMaterialAnnotation = r'''
mutation SaveMaterialAnnotation(
  $materialSlug: String!
  $unitIndex: Int!
  $anchorLabel: String
  $selectedText: String
  $noteText: String
  $color: String
) {
  saveMaterialAnnotation(
    materialSlug: $materialSlug
    unitIndex: $unitIndex
    anchorLabel: $anchorLabel
    selectedText: $selectedText
    noteText: $noteText
    color: $color
  ) {
    success
    errors
    annotation {
      id
      unitIndex
      anchorLabel
      selectedText
      noteText
      color
      updatedAt
    }
  }
}
''';

const String kDeleteMaterialAnnotation = r'''
mutation DeleteMaterialAnnotation($annotationId: ID!) {
  deleteMaterialAnnotation(annotationId: $annotationId) {
    success
    errors
  }
}
''';


const String kYouTubeSearch = r'''
query YouTubeSearch($query: String!, $maxResults: Int) {
  youtubeSearch(query: $query, maxResults: $maxResults) {
    videoId
    title
    description
    channelTitle
    thumbnailUrl
    url
  }
}
''';

const String kDueFlashcardReviews = r'''
query DueFlashcardReviews($limit: Int) {
  dueFlashcardReviews(limit: $limit) {
    id
    frontText
    backText
    easeFactor
    interval
    repetitions
    nextReviewOn
    materialId
    materialTitle
    materialSlug
  }
  dueReviewCount
}
''';

const String kSubmitFlashcardReview = r'''
mutation SubmitFlashcardReview($reviewId: ID!, $quality: Int!) {
  submitFlashcardReview(reviewId: $reviewId, quality: $quality) {
    success
    nextReviewOn
    interval
    repetitions
  }
}
''';

const String kGenerateFlashcardReviews = r'''
mutation GenerateFlashcardReviews($materialSlug: String!) {
  generateFlashcardReviews(materialSlug: $materialSlug) {
    success
    count
    errors
  }
}
''';
