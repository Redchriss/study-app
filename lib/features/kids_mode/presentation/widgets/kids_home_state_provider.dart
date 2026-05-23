import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ai_tutor/presentation/screens/ai_tutor_manager.dart';

class KidsHomeState {
  final Map<String, dynamic>? selectedSubject;
  final Map<String, dynamic>? selectedTopic;
  final Map<String, dynamic>? currentLesson;
  final List<ConversationItem> lessonItems;
  final List<Map<String, dynamic>> subjects;
  final List<Map<String, dynamic>> topics;
  final List<dynamic> quiz;
  final bool inQuiz;
  final bool isSpeaking;
  final bool loading;
  final int stars;
  final int streak;
  final bool fetchedSubjects;
  final bool showCorrectBurst;
  final Map<String, dynamic>? dailySummary;
  final Map<String, dynamic>? subjectProgress;
  final Map<String, dynamic>? lessonState;
  final Map<String, dynamic>? roadmapSummary;
  final Map<String, dynamic>? rewardProfile;
  final List<Map<String, dynamic>> topicRoadmap;
  final List<Map<String, dynamic>> reviewQueue;
  final String? quizReviewHint;
  final int selectedStoryChunk;
  final bool subjectFetchStarted;

  const KidsHomeState({
    this.selectedSubject,
    this.selectedTopic,
    this.currentLesson,
    this.lessonItems = const [],
    this.subjects = const [],
    this.topics = const [],
    this.quiz = const [],
    this.inQuiz = false,
    this.isSpeaking = false,
    this.loading = false,
    this.stars = 0,
    this.streak = 0,
    this.fetchedSubjects = false,
    this.showCorrectBurst = false,
    this.dailySummary,
    this.subjectProgress,
    this.lessonState,
    this.roadmapSummary,
    this.rewardProfile,
    this.topicRoadmap = const [],
    this.reviewQueue = const [],
    this.quizReviewHint,
    this.selectedStoryChunk = 0,
    this.subjectFetchStarted = false,
  });

  KidsHomeState copyWith({
    Map<String, dynamic>? selectedSubject,
    Map<String, dynamic>? selectedTopic,
    Map<String, dynamic>? currentLesson,
    List<ConversationItem>? lessonItems,
    List<Map<String, dynamic>>? subjects,
    List<Map<String, dynamic>>? topics,
    List<dynamic>? quiz,
    bool? inQuiz,
    bool? isSpeaking,
    bool? loading,
    int? stars,
    int? streak,
    bool? fetchedSubjects,
    bool? showCorrectBurst,
    Map<String, dynamic>? dailySummary,
    Map<String, dynamic>? subjectProgress,
    Map<String, dynamic>? lessonState,
    Map<String, dynamic>? roadmapSummary,
    Map<String, dynamic>? rewardProfile,
    List<Map<String, dynamic>>? topicRoadmap,
    List<Map<String, dynamic>>? reviewQueue,
    String? quizReviewHint,
    int? selectedStoryChunk,
    bool? subjectFetchStarted,
  }) {
    return KidsHomeState(
      selectedSubject: selectedSubject ?? this.selectedSubject,
      selectedTopic: selectedTopic ?? this.selectedTopic,
      currentLesson: currentLesson ?? this.currentLesson,
      lessonItems: lessonItems ?? this.lessonItems,
      subjects: subjects ?? this.subjects,
      topics: topics ?? this.topics,
      quiz: quiz ?? this.quiz,
      inQuiz: inQuiz ?? this.inQuiz,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      loading: loading ?? this.loading,
      stars: stars ?? this.stars,
      streak: streak ?? this.streak,
      fetchedSubjects: fetchedSubjects ?? this.fetchedSubjects,
      showCorrectBurst: showCorrectBurst ?? this.showCorrectBurst,
      dailySummary: dailySummary ?? this.dailySummary,
      subjectProgress: subjectProgress ?? this.subjectProgress,
      lessonState: lessonState ?? this.lessonState,
      roadmapSummary: roadmapSummary ?? this.roadmapSummary,
      rewardProfile: rewardProfile ?? this.rewardProfile,
      topicRoadmap: topicRoadmap ?? this.topicRoadmap,
      reviewQueue: reviewQueue ?? this.reviewQueue,
      quizReviewHint: quizReviewHint ?? this.quizReviewHint,
      selectedStoryChunk: selectedStoryChunk ?? this.selectedStoryChunk,
      subjectFetchStarted: subjectFetchStarted ?? this.subjectFetchStarted,
    );
  }
}

class KidsHomeStateNotifier extends Notifier<KidsHomeState> {
  @override
  KidsHomeState build() => const KidsHomeState();

  void apply(KidsHomeState Function(KidsHomeState) cb) {
    state = cb(state);
  }
}

final kidsHomeStateProvider =
    NotifierProvider<KidsHomeStateNotifier, KidsHomeState>(
  KidsHomeStateNotifier.new,
);
