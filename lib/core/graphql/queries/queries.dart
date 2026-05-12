// Auth
const String kTokenAuth = r'''
mutation Login($username: String!, $password: String!) {
  tokenAuth(username: $username, password: $password) {
    token
    refreshToken
    payload
  }
}
''';

const String kRegister = r'''
mutation Register($username: String!, $email: String!, $password: String!, $phone: String) {
  register(username: $username, email: $email, password: $password, phone: $phone) {
    success
    errors
    token
    refreshToken
  }
}
''';

const String kRefreshToken = r'''
mutation RefreshToken($refreshToken: String!) {
  refreshToken(refreshToken: $refreshToken) {
    token
    refreshToken
  }
}
''';

const String kUpdateProfile = r'''
mutation UpdateProfile($input: ProfileInput!) {
  updateProfile(input: $input) {
    success
    errors
    profile {
      educationLevel
      standard
      form
      term
      onboardingComplete
      aiCredits
      studyStreak
      studyPoints
    }
  }
}
''';

// Dashboard
const String kMe = r'''
query Me {
  me {
    id
    username
    email
    profile {
      educationLevel
      standard
      form
      term
      onboardingComplete
      aiCredits
      studyStreak
      studyPoints
      activePlanName
      avatarUrl
      university { id name shortName }
      program { id name }
    }
  }
}
''';

const String kDashboard = r'''
query Dashboard {
  me {
    id
    username
    profile {
      studyStreak
      studyPoints
      aiCredits
      educationLevel
      activePlanName
    }
  }
  recentMaterials(limit: 5) {
    id
    title
    contentType
    thumbnailUrl
    subject { name }
  }
  recentQuizAttempts(limit: 3) {
    id
    quiz { title }
    score
    completedAt
  }
  progressSnapshot {
    hasData
    masteryPercent
    avgQuizScore
    strongestTopics
    weakestTopics
  }
  myCircles {
    id
    name
    slug
    memberCount
  }
}
''';

// Education
const String kUniversities = r'''
query Universities {
  universities {
    id
    name
    shortName
    location
    universityType
    logoUrl
  }
}
''';

const String kPrograms = r'''
query Programs($universityId: ID!) {
  programs(universityId: $universityId) {
    id
    name
    faculty
    durationYears
  }
}
''';

const String kPrimarySchools = r'''
query PrimarySchools($search: String) {
  primarySchools(search: $search) {
    id
    name
    district
    region
  }
}
''';

const String kSecondarySchools = r'''
query SecondarySchools($search: String) {
  secondarySchools(search: $search) {
    id
    name
    district
    region
  }
}
''';

// Materials
const String kMaterials = r'''
query Materials($search: String, $contentType: String, $subjectId: ID, $limit: Int, $offset: Int) {
  materials(search: $search, contentType: $contentType, subjectId: $subjectId, limit: $limit, offset: $offset) {
    id
    title
    slug
    contentType
    thumbnailUrl
    isBookmarked
    isPremium
    subject { name }
    createdAt
  }
}
''';

const String kMaterial = r'''
query Material($slug: String!) {
  material(slug: $slug) {
    id
    title
    slug
    contentType
    description
    fileUrl
    youtubeEmbedUrl
    aiSummary
    aiFlashcardsJson
    isBookmarked
    isApproved
    subject { name educationLevel }
    uploadedBy { username }
    aiTasks {
      taskType
      status
      statusLabel
      isActive
    }
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

// Quizzes
const String kQuizzes = r'''
query Quizzes($subjectId: ID, $difficulty: String, $limit: Int) {
  quizzes(subjectId: $subjectId, difficulty: $difficulty, limit: $limit) {
    id
    title
    slug
    difficulty
    durationMinutes
    questionCount
    subject { name }
  }
}
''';

const String kQuiz = r'''
query Quiz($slug: String!) {
  quiz(slug: $slug) {
    id
    title
    slug
    description
    durationMinutes
    difficulty
    questions {
      id
      questionText
      questionType
      points
      order
      answers {
        id
        answerText
      }
    }
  }
}
''';

const String kStartQuizAttempt = r'''
mutation StartQuizAttempt($quizId: ID!) {
  startQuizAttempt(quizId: $quizId) {
    attempt {
      id
      quiz { id title durationMinutes }
    }
    errors
  }
}
''';

const String kSubmitQuizAttempt = r'''
mutation SubmitQuizAttempt($attemptId: ID!, $answers: [UserAnswerInput!]!, $timeTakenSeconds: Int!) {
  submitQuizAttempt(attemptId: $attemptId, answers: $answers, timeTakenSeconds: $timeTakenSeconds) {
    success
    pointsEarned
    errors
    attempt {
      id
      score
      correctCount
      timeDisplay
      completedAt
      userAnswers {
        isCorrect
        question { questionText concept explanation }
        selectedAnswer { answerText }
        correctAnswer { answerText explanation }
      }
    }
  }
}
''';

// AI Tutor
const String kCreateChatSession = r'''
mutation CreateChatSession($materialId: ID) {
  createChatSession(materialId: $materialId) {
    id
    title
  }
}
''';

const String kSendMessage = r'''
mutation SendMessage($sessionId: ID!, $content: String!, $materialId: ID) {
  sendMessage(sessionId: $sessionId, content: $content, materialId: $materialId) {
    success
    error
    creditsCost
    creditsRemaining
    message {
      id
      messageText
      isUser
      timestamp
    }
  }
}
''';

const String kChatMessages = r'''
query ChatMessages($sessionId: ID!) {
  chatMessages(sessionId: $sessionId) {
    id
    messageText
    isUser
    timestamp
  }
}
''';

// Past Papers / Scanner
const String kSubmitScanSession = r'''
mutation SubmitScanSession(
  $imageBase64: String!
  $fileName: String
  $subject: String
  $educationLevel: String
  $examType: String
  $year: Int
) {
  submitScanSession(
    imageBase64: $imageBase64
    fileName: $fileName
    subject: $subject
    educationLevel: $educationLevel
    examType: $examType
    year: $year
  ) {
    success
    errors
    creditsCost
    creditsRemaining
    session {
      publicId
      status
      solutions {
        questionNumber
        questionText
        steps
        answer
        explanation
        confidence
      }
    }
  }
}
''';

// Communities
const String kStudyCircles = r'''
query StudyCircles($search: String, $educationLevel: String) {
  studyCircles(search: $search, educationLevel: $educationLevel) {
    id
    name
    slug
    educationLevel
    levelDetail
    description
    memberCount
    isMember
    isFavorite
  }
}
''';

const String kMyCircles = r'''
query MyCircles {
  myCircles {
    id
    name
    slug
    educationLevel
    memberCount
  }
}
''';

const String kCirclePosts = r'''
query CirclePosts($circleSlug: String!, $sort: String) {
  circlePosts(circleSlug: $circleSlug, sort: $sort) {
    id
    title
    slug
    postType
    body
    upvoteCount
    downvoteCount
    commentCount
    isSolved
    score
    userVote
    author { username }
    createdAt
  }
}
''';

const String kPostComments = r'''
query PostComments($postId: ID!) {
  postComments(postId: $postId) {
    id
    body
    upvoteCount
    isAnswer
    author { username }
    createdAt
    replies {
      id
      body
      author { username }
      createdAt
    }
  }
}
''';

const String kJoinCircle = r'''
mutation JoinCircle($circleSlug: String!) {
  joinCircle(circleSlug: $circleSlug) {
    success
    circle { id memberCount }
  }
}
''';

const String kCreatePost = r'''
mutation CreatePost($circleSlug: String!, $title: String!, $content: String!, $postType: String) {
  createPost(circleSlug: $circleSlug, title: $title, content: $content, postType: $postType) {
    success
    errors
    post { id slug title }
  }
}
''';

const String kAddComment = r'''
mutation AddComment($postId: ID!, $content: String!, $parentId: ID) {
  addComment(postId: $postId, content: $content, parentId: $parentId) {
    success
    errors
    comment { id body author { username } createdAt }
  }
}
''';

const String kVotePost = r'''
mutation VotePost($postId: ID!, $direction: String!) {
  votePost(postId: $postId, direction: $direction) {
    success
    upvoteCount
    downvoteCount
  }
}
''';

const String kAskAiOnPost = r'''
mutation AskAiOnPost($postId: ID!) {
  askAiOnPost(postId: $postId) {
    success
    errors
    comment { id body author { username } createdAt }
  }
}
''';

// Notifications
const String kNotifications = r'''
query Notifications($unreadOnly: Boolean) {
  notifications(unreadOnly: $unreadOnly) {
    id
    notificationType
    message
    link
    isRead
    createdAt
  }
  unreadNotificationCount
}
''';

const String kMarkAllNotificationsRead = r'''
mutation MarkAllNotificationsRead {
  markAllNotificationsRead { success }
}
''';

// Payments
const String kCreditPackages = r'''
query CreditPackages {
  creditPackages {
    code
    name
    amount
    credits
    label
    purchaseType
    badge
  }
  creditLedger(limit: 10) {
    id
    entryType
    actionCode
    delta
    balanceAfter
    description
    createdAt
  }
}
''';

const String kInitializePayment = r'''
mutation InitializePayment($packageCode: String!, $purchaseType: String!) {
  initializePayment(packageCode: $packageCode, purchaseType: $purchaseType) {
    success
    checkoutUrl
    transactionId
    errors
  }
}
''';

// Kids Mode
const String kPrimarySubjects = r'''
query PrimarySubjects {
  primarySubjects {
    id
    name
    level
    isPslceSubject
    languageOfInstruction
  }
}
''';

const String kPrimaryTopics = r'''
query PrimaryTopics($subjectId: ID!, $standard: Int) {
  primaryTopics(subjectId: $subjectId, standard: $standard) {
    id
    name
    description
    standard
  }
}
''';

const String kKidLesson = r'''
query KidLesson($subjectId: ID!, $standard: Int!, $topicId: ID, $language: String) {
  kidLesson(subjectId: $subjectId, standard: $standard, topicId: $topicId, language: $language) {
    id
    title
    bodyText
    language
    quiz
    standard
  }
}
''';

const String kFetchKidLesson = r'''
mutation FetchKidLesson($subjectId: ID!, $standard: Int!, $topicId: ID, $language: String) {
  fetchKidLesson(subjectId: $subjectId, standard: $standard, topicId: $topicId, language: $language) {
    success
    errors
    lesson {
      id
      title
      bodyText
      language
      quiz
      standard
    }
  }
}
''';

const String kAnswerKidQuiz = r'''
mutation AnswerKidQuiz($lessonId: ID!, $selectedIndex: Int!) {
  answerKidQuiz(lessonId: $lessonId, selectedIndex: $selectedIndex) {
    success
    correct
    starsEarned
    streak
    errors
  }
}
''';

const String kKidProgress = r'''
query KidProgress($subjectId: ID, $standard: Int) {
  kidProgress(subjectId: $subjectId, standard: $standard) {
    id
    lessonsCompleted
    quizzesTaken
    quizzesCorrect
    starsEarned
    streak
  }
}
''';

// Parent-child account system
const String kCreateChildProfile = r'''
mutation CreateChildProfile($childName: String!, $standard: Int!, $pinCode: String!) {
  createChildProfile(childName: $childName, standard: $standard, pinCode: $pinCode) {
    success
    errors
    child {
      id
      childName
      standard
      pinCode
    }
  }
}
''';

const String kKidLogin = r'''
mutation KidLogin($username: String!, $pinCode: String!) {
  kidLogin(username: $username, pinCode: $pinCode) {
    success
    token
    errors
    child {
      id
      childName
      standard
      pinCode
    }
  }
}
''';

const String kMyChildren = r'''
query MyChildren {
  myChildren {
    id
    childName
    standard
    pinCode
    isChild
    username
    createdAt
  }
}
''';
