import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizSessionState {
  final Map<int, String> answers;
  final Map<int, bool> results;
  final int currentIndex;
  final bool showingFeedback;
  final int score;

  const QuizSessionState({
    this.answers = const {},
    this.results = const {},
    this.currentIndex = 0,
    this.showingFeedback = false,
    this.score = 0,
  });

  QuizSessionState copyWith({
    Map<int, String>? answers,
    Map<int, bool>? results,
    int? currentIndex,
    bool? showingFeedback,
    int? score,
  }) =>
      QuizSessionState(
        answers: answers ?? this.answers,
        results: results ?? this.results,
        currentIndex: currentIndex ?? this.currentIndex,
        showingFeedback: showingFeedback ?? this.showingFeedback,
        score: score ?? this.score,
      );
}

final quizSessionProvider =
    StateNotifierProvider.family<QuizSessionNotifier, QuizSessionState, String>(
  (ref, slug) => QuizSessionNotifier(slug),
);

class QuizSessionNotifier extends StateNotifier<QuizSessionState> {
  final String slug;
  QuizSessionNotifier(this.slug) : super(const QuizSessionState());

  void answerQuestion(int index, String answerId, bool isCorrect) {
    final newAnswers = Map<int, String>.from(state.answers)..[index] = answerId;
    final newResults = Map<int, bool>.from(state.results)..[index] = isCorrect;
    state = state.copyWith(
      answers: newAnswers,
      results: newResults,
      showingFeedback: true,
      score: isCorrect ? state.score + 1 : state.score,
    );
  }

  void advance() {
    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      showingFeedback: false,
    );
  }

  void goToQuestion(int index) {
    state = state.copyWith(currentIndex: index, showingFeedback: false);
  }

  void reset() {
    state = const QuizSessionState();
  }

  Future<void> saveDifficultyRating(int difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'quiz_diff_$slug';
    final history = prefs.getStringList(key) ?? [];
    history.add(difficulty.toString());
    await prefs.setStringList(key, history);
  }

  static Future<double> getAverageDifficulty(String slug) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('quiz_diff_$slug');
    if (history == null || history.isEmpty) return 0.5;
    final vals = history.map((e) => int.tryParse(e) ?? 0).toList();
    return vals.reduce((a, b) => a + b) / vals.length / 2.0;
  }
}
