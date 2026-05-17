const String kQuizzes = r'''
query Quizzes($subjectId: ID, $difficulty: String, $limit: Int) {
  quizzes(subjectId: $subjectId, difficulty: $difficulty, limit: $limit) {
    id title slug difficulty durationMinutes questionCount
    subject { name }
  }
}
''';

const String kQuiz = r'''
query Quiz($slug: String!) {
  quiz(slug: $slug) {
    id title slug description durationMinutes difficulty
    questions {
      id questionText questionType points order
      answers { id answerText }
    }
  }
}
''';

const String kStartQuizAttempt = r'''
mutation StartQuizAttempt($quizId: ID!) {
  startQuizAttempt(quizId: $quizId) {
    success
    attempt { id }
    errors
  }
}
''';

const String kQuizAttempt = r'''
query QuizAttempt($id: ID!) {
  quizAttempt(id: $id) {
    id quiz { title slug }
    score totalPoints timeTakenSeconds timeDisplay
    completed completedAt
    correctCount
    userAnswers {
      id
      isCorrect
      selectedAnswer { answerText isCorrect }
      correctAnswer { answerText isCorrect }
    }
  }
}
''';

const String kSubmitQuizAttempt = r'''
mutation SubmitQuizAttempt($attemptId: ID!, $answers: [UserAnswerInput!]!, $timeTakenSeconds: Int!) {
  submitQuizAttempt(attemptId: $attemptId, answers: $answers, timeTakenSeconds: $timeTakenSeconds) {
    success
    attempt { id score totalPoints correctCount }
    pointsEarned
    errors
  }
}
''';

const String kShareQuiz = r'''
mutation ShareQuiz($quizSlug: String!, $circleSlug: String, $makePublic: Boolean) {
  shareQuiz(quizSlug: $quizSlug, circleSlug: $circleSlug, makePublic: $makePublic) { success errors }
}
''';
