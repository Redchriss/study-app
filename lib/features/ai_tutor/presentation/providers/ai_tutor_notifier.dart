import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:genui/genui.dart' hide TextPart;
import 'package:genui/genui.dart' as genui;

import '../../../../core/storage/secure_storage.dart';
import '../screens/ai_tutor_data_service.dart';
import '../screens/ai_tutor_stream_service.dart';
import '../genui/tutor_catalog.dart' as tutor_catalog;
import 'ai_tutor_data_mixin.dart';
import 'ai_tutor_state.dart';

class AiTutorNotifier extends Notifier<AiTutorState> with AiTutorDataMixin {
  late AiTutorStreamService _streamService;
  late SurfaceController surfaceController;
  bool _disposed = false;
  late final A2uiTransportAdapter _transport;
  late final Conversation conversation;
  late Catalog catalog;
  StreamSubscription? _convSub;
  String _partialBuffer = '';
  static const int _maxRetries = 2;
  int? _lastJobId;

  @override
  AiTutorState build() {
    dataService = AiTutorDataService(ref);
    _streamService = AiTutorStreamService();
    ref.onDispose(() => _disposed = true);
    catalog = tutor_catalog.catalogForStudyMode(state.studyMode);
    surfaceController = SurfaceController(catalogs: [catalog]);
    _transport = A2uiTransportAdapter(onSend: _sendAndReceive);
    conversation =
        Conversation(controller: surfaceController, transport: _transport);
    _listenConversation();
    loadLearningProfile();
    loadTutorSnapshot();
    return const AiTutorState();
  }

  void _listenConversation() {
    _convSub?.cancel();
    _convSub = conversation.events.listen((event) {
      if (event is ConversationSurfaceAdded) {
        state = state.copyWith(conversationItems: [
          ...state.conversationItems,
          SurfaceItem(surfaceId: event.surfaceId, mounted: false),
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
          TextItem(text: event.text, isUser: false),
        ]);
      } else if (event is ConversationError) {
        state = state.copyWith(error: event.error.toString());
      }
    });
  }

  void mountSurface(String surfaceId) {
    final newItems = state.conversationItems.map((item) {
      if (item is SurfaceItem && item.surfaceId == surfaceId) {
        return SurfaceItem(surfaceId: surfaceId, mounted: true);
      }
      return item;
    }).toList();
    state = state.copyWith(conversationItems: newItems);
  }

  void setStudyMode(String mode) {
    state = state.copyWith(studyMode: mode);
    catalog = tutor_catalog.catalogForStudyMode(mode);
    surfaceController = SurfaceController(catalogs: [catalog]);
    conversation =
        Conversation(controller: surfaceController, transport: _transport);
    _listenConversation();
  }

  void toggleInsights() =>
      state = state.copyWith(showInsights: !state.showInsights);

  void newConversation() => state = state.copyWith(
        conversationItems: const [],
        sessionId: null,
        lastJobId: null,
        error: null,
        checkpointText: null,
        retryCount: 0,
      );

  void _addSpecMessage(Map<String, dynamic> spec) {
    final component = spec['component']?.toString() ?? 'Agent';
    final props = spec['props'];
    final summary = switch (component) {
      'StudyPlan' => _studyPlanSummary(props),
      'FlashCard' => _flashCardSummary(props),
      'SimpleQuiz' => _quizSummary(props),
      'StepSolver' => _stepSolverSummary(props),
      _ => 'Opened a $component activity.',
    };
    state = state.copyWith(
      conversationItems: [
        ...state.conversationItems,
        TextItem(text: summary, isUser: false),
      ],
    );
  }

  String _studyPlanSummary(dynamic props) {
    if (props is! Map) return 'Created a study plan for you.';
    final sessions = (props['sessions'] as List?)?.length ?? 0;
    final title = props['title']?.toString() ?? 'study plan';
    return 'Created $title with $sessions focused sessions.';
  }

  String _flashCardSummary(dynamic props) {
    if (props is! Map) return 'Prepared flashcards for review.';
    final cards = (props['cards'] as List?)?.length ?? 0;
    return 'Prepared $cards flashcards for review.';
  }

  String _quizSummary(dynamic props) {
    if (props is! Map) return 'Prepared a quiz for you.';
    final questions = (props['questions'] as List?)?.length ?? 0;
    final title = props['title']?.toString() ?? 'quiz';
    return 'Prepared $title with $questions questions.';
  }

  String _stepSolverSummary(dynamic props) {
    if (props is! Map) return 'Prepared a step-by-step walkthrough.';
    final steps = (props['steps'] as List?)?.length ?? 0;
    return 'Prepared a step-by-step walkthrough with $steps steps.';
  }

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
    final httpClient = http.Client();
    _partialBuffer = '';
    String currentStreamingText = '';
    try {
      await _streamService.sendStream(
        text: text,
        sessionId: state.sessionId,
        studyMode: state.studyMode,
        token: token,
        clientInstructions: clientInstructions,
        checkpointText: state.checkpointText,
        httpClient: httpClient,
        onToken: (t) {
          _partialBuffer += t;
          currentStreamingText += t;
          state = state.copyWith(
            streaming: true,
            streamingText: currentStreamingText,
          );
          _transport.addChunk(t);
        },
        onAddMessage: (msg) {
          _partialBuffer = '';
          currentStreamingText = '';
          state = state.copyWith(
            sending: false,
            streaming: false,
            streamingText: '',
            checkpointText: null,
            retryCount: 0,
          );
          loadTutorSnapshot();
        },
        onSessionId: (id) {
          state = state.copyWith(sessionId: id);
          _generateChatTitle(text);
        },
        onError: (errMsg) {
          state = state.copyWith(
            sending: false,
            streaming: false,
            error: errMsg,
          );
        },
        onJobId: (jobId) {
          _lastJobId = jobId;
          state = state.copyWith(lastJobId: jobId);
        },
        onSpec: _addSpecMessage,
        onScrollDown: () {},
      );
      if (state.streaming) {
        state = state.copyWith(
          sending: false,
          streaming: false,
          checkpointText: null,
          retryCount: 0,
        );
      }
    } on http.ClientException catch (_) {
      await _handleNetworkError(text);
    } catch (_) {
      state = state.copyWith(
        sending: false,
        streaming: false,
        error: 'Connection lost. Please try again.',
        checkpointText: _partialBuffer.isNotEmpty ? _partialBuffer : null,
      );
    } finally {
      httpClient.close();
    }
  }

  Future<void> _handleNetworkError(String originalText) async {
    final currentRetry = state.retryCount;
    if (currentRetry >= _maxRetries) {
      state = state.copyWith(
        sending: false,
        streaming: false,
        error: 'Connection lost after ${_maxRetries + 1} attempts.',
        checkpointText: _partialBuffer.isNotEmpty ? _partialBuffer : null,
        retryCount: 0,
      );
      return;
    }
    state = state.copyWith(
      retryCount: currentRetry + 1,
      checkpointText: _partialBuffer.isNotEmpty ? _partialBuffer : null,
    );
    await Future.delayed(Duration(seconds: 2 * (currentRetry + 1)));
    if (_disposed) return;
    await send(originalText, http.Client());
  }

  void _generateChatTitle(String firstMessage) {
    final items = state.conversationItems;
    final userText = items
        .whereType<TextItem>()
        .where((t) => t.isUser)
        .map((t) => t.text)
        .firstOrNull;
    final title = AiTutorState.generateTitle(userText ?? firstMessage);
    dataService.updateLastChatTitle(state.sessionId, title);
  }

  Future<void> send(String text, http.Client httpClient) async {
    if (text.isEmpty || state.sending) return;
    state = state.copyWith(
      conversationItems: [
        ...state.conversationItems,
        TextItem(text: text, isUser: true),
      ],
      sending: true,
      streaming: false,
      streamingText: '',
      error: null,
    );
    await conversation.sendRequest(ChatMessage.user(text));
  }

  Future<void> retry() async {
    final cp = state.checkpointText;
    final jobId = state.lastJobId ?? _lastJobId;
    if (jobId != null && cp != null && cp.isNotEmpty) {
      await _resumeJob(jobId, cp);
      return;
    }
    state = state.copyWith(
      sending: true,
      streaming: false,
      streamingText: cp ?? '',
      error: null,
      checkpointText: null,
      retryCount: 0,
    );
    await conversation.sendRequest(ChatMessage.user(''));
  }

  Future<void> _resumeJob(int jobId, String checkpointText) async {
    final token = await SecureStorage.getToken();
    if (token == null) {
      state = state.copyWith(sending: false);
      return;
    }
    final httpClient = http.Client();
    String currentStreamingText = checkpointText;
    _partialBuffer = checkpointText;
    try {
      await _streamService.replayJob(
        jobId: jobId,
        token: token,
        httpClient: httpClient,
        onToken: (t) {
          _partialBuffer += t;
          currentStreamingText += t;
          state = state.copyWith(
            streaming: true,
            streamingText: currentStreamingText,
          );
          _transport.addChunk(t);
        },
        onAddMessage: (_) {
          _partialBuffer = '';
          currentStreamingText = '';
          state = state.copyWith(
            sending: false,
            streaming: false,
            streamingText: '',
            checkpointText: null,
            retryCount: 0,
          );
          loadTutorSnapshot();
        },
        onSessionId: (id) => state = state.copyWith(sessionId: id),
        onError: (errMsg) {
          state = state.copyWith(
            sending: false,
            streaming: false,
            error: errMsg,
          );
        },
        onJobId: (value) {
          _lastJobId = value;
          state = state.copyWith(lastJobId: value);
        },
        onSpec: _addSpecMessage,
        onScrollDown: () {},
      );
    } finally {
      httpClient.close();
    }
  }

  void clearError() => state = state.copyWith(
        error: null,
        checkpointText: null,
        retryCount: 0,
      );
}
