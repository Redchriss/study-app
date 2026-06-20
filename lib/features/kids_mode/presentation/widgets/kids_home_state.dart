import '../../../agent/presentation/providers/agent_state.dart';

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
  final String? companionGreeting;

  final int sessionDuration;
  final int sessionRemaining;
  final bool sessionActive;
  final bool sessionWarningShown;
  final bool sessionExpired;

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
    this.companionGreeting,
    this.sessionDuration = 1200,
    this.sessionRemaining = 1200,
    this.sessionActive = false,
    this.sessionWarningShown = false,
    this.sessionExpired = false,
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
    String? companionGreeting,
    int? sessionDuration,
    int? sessionRemaining,
    bool? sessionActive,
    bool? sessionWarningShown,
    bool? sessionExpired,
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
      companionGreeting: companionGreeting ?? this.companionGreeting,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      sessionRemaining: sessionRemaining ?? this.sessionRemaining,
      sessionActive: sessionActive ?? this.sessionActive,
      sessionWarningShown: sessionWarningShown ?? this.sessionWarningShown,
      sessionExpired: sessionExpired ?? this.sessionExpired,
    );
  }

  Map<String, dynamic> toPersistable() {
    return {
      if (selectedSubject != null) 'selectedSubject': selectedSubject!,
      if (selectedTopic != null) 'selectedTopic': selectedTopic!,
      if (currentLesson != null) 'currentLesson': currentLesson!,
      'inQuiz': inQuiz,
      'selectedStoryChunk': selectedStoryChunk,
      if (quiz.isNotEmpty) 'quiz': quiz,
      'sessionRemaining': sessionRemaining,
      'sessionActive': sessionActive,
    };
  }

  static KidsHomeState Function(KidsHomeState) fromPersistable(
      Map<String, dynamic> data) {
    return (s) => s.copyWith(
          selectedSubject: data['selectedSubject'] as Map<String, dynamic>?,
          selectedTopic: data['selectedTopic'] as Map<String, dynamic>?,
          currentLesson: data['currentLesson'] as Map<String, dynamic>?,
          inQuiz: data['inQuiz'] as bool?,
          selectedStoryChunk: data['selectedStoryChunk'] as int?,
          quiz: data['quiz'] as List<dynamic>?,
          sessionRemaining: data['sessionRemaining'] as int?,
          sessionActive: data['sessionActive'] as bool?,
        );
  }
}
