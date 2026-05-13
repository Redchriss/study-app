const String kSubmitScanSession = r'''
mutation SubmitScanSession($imageBase64: String!, $fileName: String!, $subject: String!, $educationLevel: String!, $examType: String!, $year: Int) {
  submitScanSession(imageBase64: $imageBase64, fileName: $fileName, subject: $subject, educationLevel: $educationLevel, examType: $examType, year: $year) {
    success errors
    session { id publicId filename subject educationLevel examType year status creditCharged createdAt solutions { questionNumber questionText answer explanation confidence steps { text } } }
  }
}
''';

const String kPaperSolveSession = r'''
query PaperSolveSession($uuid: String!) {
  paperSolveSession(uuid: $uuid) {
    id publicId filename subject educationLevel examType year status creditCharged createdAt
    solutions { questionNumber questionText answer explanation confidence steps { text } }
  }
}
''';

const String kPaperSolveSessions = r'''
query PaperSolveSessions($limit: Int) {
  pastPapers(limit: $limit) { id title subject }
}
''';
