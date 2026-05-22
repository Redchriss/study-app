sealed class ConversationItem {}

class TextItem extends ConversationItem {
  final String text;
  final bool isUser;
  TextItem({required this.text, this.isUser = false});
}

class SurfaceItem extends ConversationItem {
  final String surfaceId;
  SurfaceItem({required this.surfaceId});
}

class AiTutorState {
  final List<ConversationItem> conversationItems;
  final String? sessionId;
  final bool sending;
  final bool streaming;
  final String streamingText;
  final String studyMode;
  final String learningStyle;
  final bool prefersExamples;
  final bool prefersStepByStep;
  final int detailLevel;
  final bool showInsights;
  final bool profileSaving;
  final bool snapshotLoading;
  final List<Map<String, dynamic>> topicStates;
  final List<Map<String, dynamic>> memories;
  final Map<String, dynamic>? activePlan;
  final int reviewCount;
  final List<Map<String, dynamic>> chatHistory;
  final String? error;

  const AiTutorState({
    this.conversationItems = const [],
    this.sessionId,
    this.sending = false,
    this.streaming = false,
    this.streamingText = '',
    this.studyMode = 'coach',
    this.learningStyle = 'mixed',
    this.prefersExamples = true,
    this.prefersStepByStep = true,
    this.detailLevel = 2,
    this.showInsights = false,
    this.profileSaving = false,
    this.snapshotLoading = true,
    this.topicStates = const [],
    this.memories = const [],
    this.activePlan,
    this.reviewCount = 0,
    this.chatHistory = const [],
    this.error,
  });

  AiTutorState copyWith({
    List<ConversationItem>? conversationItems,
    String? sessionId,
    bool? sending,
    bool? streaming,
    String? streamingText,
    String? studyMode,
    String? learningStyle,
    bool? prefersExamples,
    bool? prefersStepByStep,
    int? detailLevel,
    bool? showInsights,
    bool? profileSaving,
    bool? snapshotLoading,
    List<Map<String, dynamic>>? topicStates,
    List<Map<String, dynamic>>? memories,
    Map<String, dynamic>? activePlan,
    int? reviewCount,
    List<Map<String, dynamic>>? chatHistory,
    String? error,
  }) {
    return AiTutorState(
      conversationItems: conversationItems ?? this.conversationItems,
      sessionId: sessionId ?? this.sessionId,
      sending: sending ?? this.sending,
      streaming: streaming ?? this.streaming,
      streamingText: streamingText ?? this.streamingText,
      studyMode: studyMode ?? this.studyMode,
      learningStyle: learningStyle ?? this.learningStyle,
      prefersExamples: prefersExamples ?? this.prefersExamples,
      prefersStepByStep: prefersStepByStep ?? this.prefersStepByStep,
      detailLevel: detailLevel ?? this.detailLevel,
      showInsights: showInsights ?? this.showInsights,
      profileSaving: profileSaving ?? this.profileSaving,
      snapshotLoading: snapshotLoading ?? this.snapshotLoading,
      topicStates: topicStates ?? this.topicStates,
      memories: memories ?? this.memories,
      activePlan: activePlan ?? this.activePlan,
      reviewCount: reviewCount ?? this.reviewCount,
      chatHistory: chatHistory ?? this.chatHistory,
      error: error ?? this.error,
    );
  }
}
