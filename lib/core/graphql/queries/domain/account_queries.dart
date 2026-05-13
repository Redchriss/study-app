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
