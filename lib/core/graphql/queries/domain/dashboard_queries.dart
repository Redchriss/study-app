const String kDashboard = r'''
query Dashboard {
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
  recentMaterials(limit: 5) {
    id
    title
    slug
    contentType
    thumbnailUrl
    subject { name }
  }
  latestMaterialProgress {
    currentUnit
    totalUnits
    progressPercent
    lastPositionLabel
    lastOpenedAt
    material {
      id
      slug
      title
      contentType
      subject { name }
    }
  }
  recentQuizAttempts(limit: 3) {
    id
    quiz { title }
    score
    correctCount
    totalPoints
    timeTakenSeconds
    completedAt
  }
  progressSnapshot {
    hasData
    masteryPercent
    avgQuizScore
    questionsPracticed
    questionsCorrect
    attemptCount
    strongestTopics { name accuracy questionsCorrect questionsSeen }
    weakestTopics { name accuracy questionsCorrect questionsSeen }
  }
  activityFeed(limit: 5) {
    kind
    message
    detail
    createdAt
  }
  learningProfile {
    learningStyle
  }
  myCircles {
    id
    name
    slug
    memberCount
  }
}
''';

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
      primarySchool { id name district region }
      secondarySchool { id name district region }
      university { id name shortName location universityType description }
      program { id name faculty durationYears }
    }
  }
}
''';

const String kActivityFeed = r'''
query ActivityFeed($limit: Int) {
  activityFeed(limit: $limit) { kind message detail createdAt }
  learningProfile { learningStyle }
}
''';

const String kPopularQuizzes = r'''
query PopularQuizzes {
  popularQuizzes { id title slug subjectName completionsCount averageScore }
}
''';
