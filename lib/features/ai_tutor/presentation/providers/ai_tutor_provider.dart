import 'ai_tutor_state.dart';
export 'ai_tutor_state.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:genui/genui.dart' hide TextPart;
import 'package:genui/genui.dart' as genui;

import '../../../../core/storage/secure_storage.dart';
import '../screens/ai_tutor_data_service.dart';
import '../screens/ai_tutor_stream_service.dart';
import '../genui/tutor_catalog.dart';

final aiTutorProvider = NotifierProvider<AiTutorNotifier, AiTutorState>(
  AiTutorNotifier.new,
);

class AiTutorNotifier extends Notifier<AiTutorState> {
  late AiTutorDataService _dataService;
  late AiTutorStreamService _streamService;

  late final SurfaceController surfaceController;
  late final A2uiTransportAdapter _transport;
  late final Conversation conversation;
  late final Catalog catalog;

  @override
  AiTutorState build() {
    _dataService = AiTutorDataService(ref as WidgetRef);
    _streamService = AiTutorStreamService();

    catalog = buildTutorCatalog();
    surfaceController = SurfaceController(catalogs: [catalog]);
    _transport = A2uiTransportAdapter(onSend: _sendAndReceive);
    conversation =
        Conversation(controller: surfaceController, transport: _transport);

    conversation.events.listen((event) {
      if (event is ConversationSurfaceAdded) {
        state = state.copyWith(conversationItems: [
          ...state.conversationItems,
          SurfaceItem(surfaceId: event.surfaceId)
        ]);
      } else if (event is ConversationSurfaceRemoved) {
        final newItems = state.conversationItems
            .where((item) =>
                !(item is SurfaceItem && item.surfaceId == event.surfaceId))
            .toList();
        state = state.copyWith(conversationItems: newItems);
      } else if (event is ConversationContentReceived) {
        state = state.copyWith(conversationItems: [
          ...state.conversationItems,
          TextItem(text: event.text, isUser: false)
        ]);
      } else if (event is ConversationError) {
        state = state.copyWith(error: event.error.toString());
      }
    });

    loadLearningProfile();
    loadTutorSnapshot();
    return const AiTutorState();
  }

  void setStudyMode(String mode) => state = state.copyWith(studyMode: mode);

  void toggleInsights() =>
      state = state.copyWith(showInsights: !state.showInsights);

  void newConversation() => state = state.copyWith(
        conversationItems: const [],
        sessionId: null,
      );

  Future<void> _sendAndReceive(ChatMessage msg) async {
    final buffer = StringBuffer();
    for (final part in msg.parts) {
      if (part.isUiInteractionPart) {
        buffer.write(part.asUiInteractionPart!.interaction);
      } else if (part is genui.TextPart) {
        buffer.write(part.text);
      }
    }
    final text = buffer.toString();
    if (text.isEmpty) return;

    final token = await SecureStorage.getToken();
    if (token == null) {
      state = state.copyWith(sending: false);
      return;
    }

    final promptBuilder = PromptBuilder.chat(catalog: catalog);
    final clientInstructions = promptBuilder.systemPromptJoined();

    try {
      await _streamService.sendStream(
        text: text,
        sessionId: state.sessionId,
        studyMode: state.studyMode,
        token: token,
        clientInstructions: clientInstructions,
        httpClient: http.Client(),
        onToken: (t) {
          _transport.addChunk(t);
        },
        onAddMessage: (msg) {
          state = state.copyWith(sending: false);
          loadTutorSnapshot();
        },
        onSessionId: (id) => state = state.copyWith(sessionId: id),
        onError: (msg) {
          state = state.copyWith(
            sending: false,
            error: msg,
          );
        },
        onScrollDown: () {},
      );

      state = state.copyWith(sending: false);
    } catch (_) {
      state = state.copyWith(
        sending: false,
        error: 'Connection lost. Please try again.',
      );
    }
  }

  Future<void> send(String text, http.Client httpClient) async {
    if (text.isEmpty || state.sending) return;

    state = state.copyWith(
      conversationItems: [
        ...state.conversationItems,
        TextItem(text: text, isUser: true)
      ],
      sending: true,
    );
    await conversation.sendRequest(ChatMessage.user(text));
  }

  void clearError() => state = state.copyWith(error: null);

  Future<void> loadLearningProfile() async {
    try {
      final profile = await _dataService.loadLearningProfile();
      if (profile == null) return;
      state = state.copyWith(
        learningStyle:
            (profile['learningStyle']?.toString().trim().isNotEmpty == true)
                ? profile['learningStyle'].toString()
                : 'mixed',
        prefersExamples: profile['prefersExamples'] as bool? ?? true,
        prefersStepByStep: profile['prefersStepByStep'] as bool? ?? true,
        detailLevel: profile['detailLevel'] as int? ?? 2,
      );
    } catch (_) {}
  }

  Future<void> loadTutorSnapshot() async {
    try {
      final snapshot = await _dataService.loadTutorSnapshot();
      if (snapshot == null) return;
      state = state.copyWith(
        topicStates: ((snapshot['topicStates'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(),
        memories: ((snapshot['memories'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(),
        activePlan: snapshot['latestPlan'] is Map
            ? Map<String, dynamic>.from(snapshot['latestPlan'] as Map)
            : null,
        reviewCount: (snapshot['reviewCount'] as num?)?.toInt() ?? 0,
        snapshotLoading: false,
      );
    } catch (_) {
      state = state.copyWith(snapshotLoading: false);
    }
  }

  Future<void> loadChatHistory() async {
    try {
      final sessions = await _dataService.loadChatHistory();
      state = state.copyWith(
        chatHistory: sessions
            .whereType<Map>()
            .map((s) => Map<String, dynamic>.from(s))
            .toList(),
      );
    } catch (_) {}
  }

  Future<void> restoreSession(String id) async {
    try {
      final msgs = await _dataService.restoreSession(id);
      final newItems = <ConversationItem>[];
      for (final m in msgs.whereType<Map>()) {
        newItems.add(TextItem(
            text: m['messageText'] as String? ?? '',
            isUser: m['isUser'] as bool? ?? false));
      }
      state = state.copyWith(
        sessionId: id,
        conversationItems: newItems,
      );
    } catch (_) {}
  }

  Future<void> createAdaptivePlan(String? goalText) async {
    final payload = await _dataService.createAdaptivePlan(
      goal: (goalText?.trim().isEmpty ?? true) ? null : goalText?.trim(),
      subjectName: state.topicStates.isNotEmpty
          ? state.topicStates.first['subjectName']?.toString()
          : null,
      studyMode: state.studyMode,
    );
    if (payload?['success'] == true && payload?['plan'] is Map) {
      state = state.copyWith(
        activePlan: Map<String, dynamic>.from(payload!['plan'] as Map),
      );
      loadTutorSnapshot();
      return;
    }
    final errMsg = (payload?['errors'] as List?)?.cast<String>().join(', ');
    state = state.copyWith(
      error: errMsg?.isNotEmpty == true ? errMsg : 'Could not build a plan.',
    );
  }

  Future<void> saveLearningProfile({
    required String learningStyle,
    required bool prefersExamples,
    required bool prefersStepByStep,
    required int detailLevel,
  }) async {
    state = state.copyWith(profileSaving: true);
    try {
      final payload = await _dataService.saveLearningProfile(
        learningStyle: learningStyle,
        prefersExamples: prefersExamples,
        prefersStepByStep: prefersStepByStep,
        detailLevel: detailLevel,
      );
      if (payload?['success'] == true) {
        state = state.copyWith(
          learningStyle: learningStyle,
          prefersExamples: prefersExamples,
          prefersStepByStep: prefersStepByStep,
          detailLevel: detailLevel,
        );
      }
    } finally {
      state = state.copyWith(profileSaving: false);
    }
  }

  void setMessageFeedback(int index, String? feedback) {
    // Left unimplemented for GenUI currently, as we use conversationItems
  }
}
