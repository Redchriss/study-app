const String kChatSessions = r'''
query ChatSessions {
  chatSessions {
    id title updatedAt
  }
}
''';

const String kCreateChatSession = r'''
mutation CreateChatSession($materialId: ID) {
  createChatSession(materialId: $materialId) {
    session { id title }
  }
}
''';

const String kSendMessage = r'''
mutation SendMessage($sessionId: ID!, $content: String!, $materialId: ID, $studyMode: String, $clientInstructions: String) {
  sendMessage(
    sessionId: $sessionId
    content: $content
    materialId: $materialId
    studyMode: $studyMode
    clientInstructions: $clientInstructions
  ) {
    success
    error
    message { id messageText isUser timestamp }
    creditsCost
    creditsRemaining
  }
}
''';

const String kChatMessages = r'''
query ChatMessages($sessionId: ID!) {
  chatMessages(sessionId: $sessionId) {
    id messageText isUser timestamp
  }
}
''';

const String kTutorSnapshot = r'''
query TutorSnapshot {
  tutorSnapshot {
    learnerContext
    reviewCount
    topicStates {
      topicName
      topicSlug
      subjectName
      masteryScore
      confidenceScore
      timesPracticed
      timesStruggled
      lastMode
      lastOutcome
      nextReviewOn
      statusLabel
    }
    memories {
      memoryType
      title
      body
      topicSlug
      subjectName
      importance
    }
    latestPlan {
      id
      title
      goal
      studyMode
      subjectName
      planSummary
      tasksJson
      active
      updatedAt
    }
  }
}
''';

const String kAdaptiveStudyPlan = r'''
query AdaptiveStudyPlan {
  adaptiveStudyPlan {
    id
    title
    goal
    studyMode
    subjectName
    planSummary
    tasksJson
    active
    updatedAt
  }
}
''';

const String kSetMessageFeedback = r'''
mutation SetMessageFeedback($messageId: ID!, $feedback: String) {
  setMessageFeedback(messageId: $messageId, feedback: $feedback) {
    success
    errors
  }
}
''';

const String kCreateAdaptiveStudyPlan = r'''
mutation CreateAdaptiveStudyPlan($goal: String, $subjectName: String, $studyMode: String) {
  createAdaptiveStudyPlan(goal: $goal, subjectName: $subjectName, studyMode: $studyMode) {
    success
    errors
    plan {
      id
      title
      goal
      studyMode
      subjectName
      planSummary
      tasksJson
      active
      updatedAt
    }
  }
}
''';
