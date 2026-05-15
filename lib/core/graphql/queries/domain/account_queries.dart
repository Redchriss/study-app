const String kLeaderboard = r'''
query Leaderboard {
  me { username profile { studyPoints studyStreak } }
}
''';

const String kLeaderboardRankings = r'''
query LeaderboardRankings($category: String, $limit: Int) {
  leaderboard(category: $category, limit: $limit) {
    username score quizCount questionsCorrect
  }
}
''';

const String kLearningProfile = r'''
query LearningProfile {
  learningProfile {
    learningStyle
    prefersExamples
    prefersStepByStep
    detailLevel
    totalQuestions
    summarizeRequests
    explainRequests
    quizRequests
    exampleRequests
    avgQuizScore
    topicsMastered
    topicsStruggling
  }
}
''';

const String kUpdateLearningProfile = r'''
mutation UpdateLearningProfile(
  $learningStyle: String
  $prefersExamples: Boolean
  $prefersStepByStep: Boolean
  $detailLevel: Int
) {
  updateLearningProfile(
    learningStyle: $learningStyle
    prefersExamples: $prefersExamples
    prefersStepByStep: $prefersStepByStep
    detailLevel: $detailLevel
  ) {
    success
    errors
    profile {
      learningStyle
      prefersExamples
      prefersStepByStep
      detailLevel
      totalQuestions
      summarizeRequests
      explainRequests
      quizRequests
      exampleRequests
      avgQuizScore
      topicsMastered
      topicsStruggling
    }
  }
}
''';
