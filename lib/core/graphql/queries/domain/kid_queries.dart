const String kPrimarySubjects = r'''
query PrimarySubjects($standard: Int, $educationTrack: String) {
  primarySubjects(standard: $standard, educationTrack: $educationTrack) { id name }
}
''';

const String kKidDailySummary = r'''
query KidDailySummary {
  kidDailySummary {
    date
    activitiesToday
    dailyGoal
    chestAvailable
    chestClaimed
    calendarStreak
    totalStars
  }
}
''';

const String kClaimKidDailyChest = r'''
mutation ClaimKidDailyChest {
  claimKidDailyChest {
    success errors
    summary {
      date
      activitiesToday
      dailyGoal
      chestAvailable
      chestClaimed
      calendarStreak
      totalStars
    }
  }
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
    id title bodyText quiz language
  }
}
''';

const String kFetchKidLesson = r'''
mutation FetchKidLesson($subjectId: ID!, $standard: Int!, $topicId: ID) {
  fetchKidLesson(subjectId: $subjectId, standard: $standard, topicId: $topicId) {
    success errors
    lesson { id title bodyText quiz }
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

const String kKidRewardProfile = r'''
query KidRewardProfile {
  kidRewardProfile {
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
}
''';

const String kEquipKidCompanion = r'''
mutation EquipKidCompanion($code: String!) {
  equipKidCompanion(code: $code) {
    success
    errors
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
  }
}
''';

const String kParentKidOverview = r'''
query ParentKidOverview {
  parentKidOverview {
    childId
    childName
    standard
    educationTrack
    streak
    totalStars
    readyReviewCount
    masteredCount
    currentLevel
    xp
    strongestSubject
    supportTip
    recentBadges {
      code
      title
      description
      iconKey
      earnedAt
    }
  }
}
''';

const String kCreateChildProfile = r'''
mutation CreateChildProfile($childName: String!, $standard: Int!, $pinCode: String!, $educationTrack: String) {
  createChildProfile(childName: $childName, standard: $standard, pinCode: $pinCode, educationTrack: $educationTrack) {
    success errors
    child { id childName standard childEducationTrack }
  }
}
''';

const String kKidLogin = r'''
mutation KidLogin($username: String!, $pinCode: String!) {
  kidLogin(username: $username, pinCode: $pinCode) {
    success token errors
    child { id childName standard isChild username childEducationTrack kidBonusStars }
  }
}
''';

const String kMyChildren = r'''
query MyChildren {
  myChildren {
    id childName standard isChild username createdAt childEducationTrack kidBonusStars
  }
}
''';
