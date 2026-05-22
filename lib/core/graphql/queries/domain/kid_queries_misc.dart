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
    success token refreshToken errors
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
