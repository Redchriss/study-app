// AI 2.0 GraphQL queries for knowledge graph, learner model, assessment, and orchestrator.

// ─── Knowledge Graph ─────────────────────────────────

const String kKnowledgeSubjects = r'''
query KnowledgeSubjects($educationLevel: String, $code: String) {
  knowledgeSubjects(educationLevel: $educationLevel, code: $code) {
    id name code educationLevel
  }
}
''';

const String kKnowledgeTree = r'''
query KnowledgeTree($subjectId: ID!) {
  knowledgeTree(subjectId: $subjectId) {
    topic { name slug standardOrForm displayOrder }
    concepts { id name slug conceptType difficulty }
    prerequisites { fromConcept { slug } toConcept { slug } strength }
  }
}
''';

// ─── Learner Model ──────────────────────────────────

const String kMyKnowledgeState = r'''
query MyKnowledgeState($subjectCode: String!) {
  myKnowledgeState(subjectCode: $subjectCode) {
    conceptSlug
    conceptName
    conceptType
    topicName
    subjectCode
    pKnow
    confidence
    totalObservations
    nextReviewAt
    difficulty
    isReadyToLearn
    prerequisiteSlugs
  }
}
''';

const String kExamReadiness = r'''
query ExamReadiness($subjectCode: String!) {
  examReadiness(subjectCode: $subjectCode)
}
''';

const String kReadyToLearn = r'''
query ReadyToLearn($subjectCode: String) {
  readyToLearn(subjectCode: $subjectCode) {
    conceptSlug
    conceptName
    topicName
    pKnow
    difficulty
  }
}
''';

const String kDueReviews = r'''
query DueReviews($subjectCode: String, $limit: Int) {
  dueReviews(subjectCode: $subjectCode, limit: $limit) {
    id
    pKnow
    nextReviewAt
    conceptName
    conceptSlug
    subjectCode
  }
}
''';

// ─── Diagnostic Assessment ──────────────────────────

const String kStartDiagnostic = r'''
mutation StartDiagnostic($subjectCode: String!, $scope: String) {
  startDiagnostic(subjectCode: $subjectCode, scope: $scope) {
    session { id scope status abilityTheta abilitySe }
    firstQuestion {
      id questionText conceptSlug difficulty
      answers { id text }
    }
    totalQuestionCount
  }
}
''';

const String kSubmitDiagnosticAnswer = r'''
mutation SubmitDiagnosticAnswer($sessionId: ID!, $questionId: ID!, $answerId: ID, $textAnswer: String, $responseTimeMs: Int) {
  submitDiagnosticAnswer(
    sessionId: $sessionId
    questionId: $questionId
    answerId: $answerId
    textAnswer: $textAnswer
    responseTimeMs: $responseTimeMs
  ) {
    correct
    explanation
    nextQuestion {
      id questionText conceptSlug difficulty
      answers { id text }
    }
    sessionComplete
    session { id status abilityTheta abilitySe knowledgeMap }
    abilityTheta
    abilitySe
  }
}
''';

const String kMyDiagnosticSessions = r'''
query MyDiagnosticSessions($subjectCode: String) {
  myDiagnosticSessions(subjectCode: $subjectCode) {
    id scope status abilityTheta abilitySe overallAccuracy completedAt
  }
}
''';

// ─── Orchestrator ──────────────────────────────────

const String kNextAction = r'''
query NextAction($subjectCode: String) {
  nextAction(subjectCode: $subjectCode) {
    id actionType priority
    conceptName conceptSlug subjectCode
    teachingStrategy
    reason
    isActive
    createdAt
  }
}
''';
