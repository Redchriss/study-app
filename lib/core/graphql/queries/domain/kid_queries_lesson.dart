const String kPrimarySubjects = r'''
query PrimarySubjects($standard: Int, $educationTrack: String) {
  primarySubjects(standard: $standard, educationTrack: $educationTrack) { id name }
}
''';

const String kPrimaryTopics = r'''
query PrimaryTopics($subjectId: ID!, $standard: Int!) {
  primaryTopics(subjectId: $subjectId, standard: $standard) {
    id name slug
  }
}
''';

const String kKidLesson = r'''
query KidLesson($subjectId: ID!, $standard: Int!, $topicId: ID) {
  kidLesson(subjectId: $subjectId, standard: $standard, topicId: $topicId) {
    id title bodyText quiz chunks language
  }
}
''';

const String kFetchKidLesson = r'''
mutation FetchKidLesson($subjectId: ID!, $standard: Int!, $topicId: ID, $language: String) {
  fetchKidLesson(subjectId: $subjectId, standard: $standard, topicId: $topicId, language: $language) {
    success errors
    lesson { id title bodyText quiz chunks }
    state {
      lessonsOpened
      quizAttempts
      quizCorrect
      masteryLevel
      readyForReview
      statusLabel
      nextReviewLabel
    }
  }
}
''';

const String kAnswerKidQuiz = r'''
mutation AnswerKidQuiz($lessonId: ID!, $selectedIndex: Int!) {
  answerKidQuiz(lessonId: $lessonId, selectedIndex: $selectedIndex) {
    success correct starsEarned streak masteryLevel nextReviewLabel errors
    rewardProfile {
      xp
      level
      coins
      equippedCompanion
      unlockedCompanions
      progressToNextLevel
      nextLevelXp
      availableCompanions {
        code
        title
        description
        accent
        unlockLevel
        unlocked
        equipped
      }
      recentBadges {
        code
        title
        description
        iconKey
        earnedAt
      }
    }
    newBadges {
      code
      title
      description
      iconKey
      earnedAt
    }
  }
}
''';

const String kKidProgress = r'''
query KidProgress($subjectId: ID!, $standard: Int!) {
  kidProgress(subjectId: $subjectId, standard: $standard) {
    lessonsCompleted quizzesTaken quizzesCorrect starsEarned
  }
}
''';

const String kKidSubjectRoadmap = r'''
query KidSubjectRoadmap($subjectId: ID!, $standard: Int!) {
  kidSubjectRoadmap(subjectId: $subjectId, standard: $standard) {
    summary {
      readyReviewCount
      masteredCount
      inProgressCount
      untouchedCount
      nextTopicId
      reviewTopicId
    }
    topics {
      topicId
      topicName
      topicSlug
      lessonAvailable
      state {
        masteryLevel
        quizAttempts
        quizCorrect
        readyForReview
        statusLabel
        nextReviewLabel
        isMastered
      }
    }
    worlds {
      worldId
      title
      subtitle
      topicCount
      masteredCount
      readyReviewCount
      inProgressCount
      unlocked
      completed
      topics {
        topicId
        topicName
        topicSlug
        lessonAvailable
        state {
          masteryLevel
          quizAttempts
          quizCorrect
          readyForReview
          statusLabel
          nextReviewLabel
          isMastered
        }
      }
    }
  }
}
''';

const String kKidReviewQueue = r'''
query KidReviewQueue($limit: Int) {
  kidReviewQueue(limit: $limit) {
    topicId
    topicName
    topicSlug
    lessonAvailable
    state {
      masteryLevel
      readyForReview
      statusLabel
      nextReviewLabel
      isMastered
    }
  }
}
''';
