sealed class ConversationItem {}

class TextItem extends ConversationItem {
  final String text;
  final bool isUser;
  final String? id;
  final String? confidenceLabel;
  final double? confidenceScore;
  final String? feedback;

  TextItem({
    required this.text,
    this.isUser = false,
    this.id,
    this.confidenceLabel,
    this.confidenceScore,
    this.feedback,
  });

  TextItem copyWith({
    String? text,
    bool? isUser,
    String? id,
    String? confidenceLabel,
    double? confidenceScore,
    String? feedback,
  }) {
    return TextItem(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      id: id ?? this.id,
      confidenceLabel: confidenceLabel ?? this.confidenceLabel,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      feedback: feedback ?? this.feedback,
    );
  }
}

class SurfaceItem extends ConversationItem {
  final String surfaceId;
  final bool mounted;
  SurfaceItem({required this.surfaceId, this.mounted = false});
}

class AgentState {
  final List<ConversationItem> conversationItems;
  final String? sessionId;
  final int? lastJobId;
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
  final String? checkpointText;
  final int agentFreeRemaining;
  final int retryCount;

  const AgentState({
    this.conversationItems = const [],
    this.sessionId,
    this.lastJobId,
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
    this.checkpointText,
    this.agentFreeRemaining = 10,
    this.retryCount = 0,
  });

  AgentState copyWith({
    List<ConversationItem>? conversationItems,
    String? sessionId,
    int? lastJobId,
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
    String? checkpointText,
    int? agentFreeRemaining,
    int? retryCount,
  }) {
    return AgentState(
      conversationItems: conversationItems ?? this.conversationItems,
      sessionId: sessionId ?? this.sessionId,
      lastJobId: lastJobId ?? this.lastJobId,
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
      checkpointText: checkpointText ?? this.checkpointText,
      agentFreeRemaining: agentFreeRemaining ?? this.agentFreeRemaining,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  static String generateTitle(String firstMessage) {
    final cleaned = firstMessage.trim();
    if (cleaned.length <= 48) return cleaned;
    return '${cleaned.substring(0, 45)}...';
  }
}
