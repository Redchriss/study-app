import 'dart:async';

import 'ai_tutor_state.dart';
export 'ai_tutor_state.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:genui/genui.dart' hide TextPart;
import 'package:genui/genui.dart' as genui;

import '../../../../core/storage/secure_storage.dart';
import '../screens/ai_tutor_data_service.dart';
import '../screens/ai_tutor_stream_service.dart';
import '../genui/tutor_catalog.dart' as tutor_catalog;
import 'ai_tutor_data_mixin.dart';

final aiTutorProvider = NotifierProvider<AiTutorNotifier, AiTutorState>(
  AiTutorNotifier.new,
);

class AiTutorNotifier extends Notifier<AiTutorState> with AiTutorDataMixin {
  late AiTutorStreamService _streamService;

  late final SurfaceController surfaceController;
  late final A2uiTransportAdapter _transport;
  late final Conversation conversation;
  late final Catalog catalog;
  StreamSubscription? _convSub;

  @override
  AiTutorState build() {
    dataService = AiTutorDataService(ref as WidgetRef);
    _streamService = AiTutorStreamService();

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

    final httpClient = http.Client();
    try {
      await _streamService.sendStream(
        text: text,
        sessionId: state.sessionId,
        studyMode: state.studyMode,
        token: token,
        clientInstructions: clientInstructions,
        httpClient: httpClient,
        onToken: (t) {
          state = state.copyWith(
            streaming: true,
            streamingText: state.streamingText + t,
          );
          _transport.addChunk(t);
        },
        onAddMessage: (msg) {
          state = state.copyWith(
            sending: false,
            streaming: false,
            streamingText: '',
          );
          loadTutorSnapshot();
        },
        onSessionId: (id) => state = state.copyWith(sessionId: id),
        onError: (msg) {
          state = state.copyWith(
            sending: false,
            streaming: false,
            error: msg,
          );
        },
        onScrollDown: () {},
      );

      state = state.copyWith(
        sending: false,
        streaming: false,
      );
    } catch (_) {
      state = state.copyWith(
        sending: false,
        streaming: false,
        error: 'Connection lost. Please try again.',
      );
    } finally {
      httpClient.close();
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
}
