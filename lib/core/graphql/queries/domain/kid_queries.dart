const String kPrimarySubjects = r'''
query PrimarySubjects {
  primarySubjects(standard: 1) { id name slug }
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
    progress { lessonsCompleted quizzesTaken starsEarned }
  }
}
''';

const String kAnswerKidQuiz = r'''
mutation AnswerKidQuiz($lessonId: ID!, $questionId: ID!, $selectedIndex: Int!) {
  answerKidQuiz(lessonId: $lessonId, questionId: $questionId, selectedIndex: $selectedIndex) {
    correct starsEarned
    oldProgress { lessonsCompleted quizzesTaken quizzesCorrect starsEarned }
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

const String kCreateChildProfile = r'''
mutation CreateChildProfile($childName: String!, $standard: Int!, $pinCode: String!) {
  createChildProfile(childName: $childName, standard: $standard, pinCode: $pinCode) {
    success errors
    child { id childName standard }
  }
}
''';

const String kKidLogin = r'''
mutation KidLogin($username: String!, $pinCode: String!) {
  kidLogin(username: $username, pinCode: $pinCode) {
    success token errors
    child { id childName standard isChild username }
  }
}
''';

const String kMyChildren = r'''
query MyChildren {
  myChildren {
    id childName standard isChild username createdAt
  }
}
''';
