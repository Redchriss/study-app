import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:genui/genui.dart' hide TextPart;
import 'package:genui/genui.dart' as genui;
import '../../../../core/storage/secure_storage.dart';
import '../genui/tutor_catalog.dart';
import '../providers/ai_tutor_state.dart';
export '../providers/ai_tutor_state.dart'
    show ConversationItem, TextItem, SurfaceItem;
import 'ai_tutor_data_service.dart';
import 'ai_tutor_stream_service.dart';

class AiTutorManager {
  late void Function(VoidCallback) _setState;
  late bool Function() _isMounted;
  late VoidCallback _onScrollDown;
  late void Function(String) _onShowError;
  late AiTutorDataService _dataService;
  late AiTutorStreamService _streamService;

  // GenUI Controllers
  late SurfaceController controller;
  late A2uiTransportAdapter _transport;
  late Conversation conversation;
  late Catalog catalog;
  List<ConversationItem> conversationItems = [];

  String? sessionId;
  bool sending = false;
  String studyMode = 'coach';
  String learningStyle = 'mixed';
  bool prefersExamples = true;
  bool prefersStepByStep = true;
  int detailLevel = 2;
  bool showInsights = false;
  bool profileSaving = false;
  bool snapshotLoading = true;
  List<Map<String, dynamic>> topicStates = [];
  List<Map<String, dynamic>> memories = [];
  Map<String, dynamic>? activePlan;
  int reviewCount = 0;
  List<Map<String, dynamic>> chatHistory = [];

  void attach({
    required WidgetRef ref,
    required void Function(VoidCallback) setState,
    required bool Function() isMounted,
    required VoidCallback onScrollDown,
    required void Function(String) onShowError,
  }) {
    _setState = setState;
    _isMounted = isMounted;
    _onScrollDown = onScrollDown;
    _onShowError = onShowError;
    _dataService = AiTutorDataService(ref);
    _streamService = AiTutorStreamService();

    catalog = buildTutorCatalog();
    controller = SurfaceController(catalogs: [catalog]);
    _transport = A2uiTransportAdapter(onSend: _sendAndReceive);
    conversation = Conversation(controller: controller, transport: _transport);

    conversation.events.listen((event) {
      if (!_isMounted()) return;
      _setState(() {
        if (event is ConversationSurfaceAdded) {
          conversationItems.add(SurfaceItem(surfaceId: event.surfaceId));
          _onScrollDown();
        } else if (event is ConversationSurfaceRemoved) {
          conversationItems.removeWhere((item) =>
              item is SurfaceItem && item.surfaceId == event.surfaceId);
        } else if (event is ConversationContentReceived) {
          conversationItems.add(TextItem(text: event.text, isUser: false));
          _onScrollDown();
        } else if (event is ConversationError) {
          _onShowError(event.error.toString());
        }
      });
    });
  }

  void _resetStream() => _setState(() {
        sending = false;
      });

  Future<void> _sendAndReceive(ChatMessage msg) async {
    final buffer = StringBuffer();
    for (final part in msg.parts) {
      if (part.isUiInteractionPart) {
        buffer.write(part.asUiInteractionPart!.interaction);
      } else if (part is genui.TextPart) {
        buffer.write(part.text);
      }
    }
    if (buffer.isEmpty) return;

    final text = buffer.toString();
    final token = await SecureStorage.getToken();
    if (token == null) {
      _resetStream();
      return;
    }

    final promptBuilder = PromptBuilder.chat(catalog: catalog);
    final clientInstructions = promptBuilder.systemPromptJoined();

    try {
      await _streamService.sendStream(
        text: text,
        sessionId: sessionId,
        studyMode: studyMode,
        token: token,
        clientInstructions: clientInstructions,
        httpClient: http.Client(),
        onToken: (t) {
          _transport.addChunk(t);
        },
        onAddMessage: (fullText) {
          _resetStream();
          loadTutorSnapshot();
        },
        onSessionId: (id) => sessionId = id,
        onError: (msg) {
          if (_isMounted()) {
            _resetStream();
            _onShowError(msg);
          }
        },
        onScrollDown: _onScrollDown,
      );
    } catch (_) {
      if (!_isMounted()) return;
      _resetStream();
      _onShowError.call('Connection lost. Please try again.');
    }
  }

  Future<void> send(String text, http.Client httpClient) async {
    if (text.isEmpty || sending) return;
    _setState(() {
      sending = true;
      conversationItems.add(TextItem(text: text, isUser: true));
    });
    _onScrollDown();
    await conversation.sendRequest(ChatMessage.user(text));
  }

  Future<void> loadLearningProfile() async {
    final profile = await _dataService.loadLearningProfile();
    if (!_isMounted() || profile == null) return;
    _setState(() {
      learningStyle =
          profile['learningStyle']?.toString().trim().isNotEmpty == true
              ? profile['learningStyle'].toString()
              : 'mixed';
      prefersExamples = profile['prefersExamples'] as bool? ?? true;
      prefersStepByStep = profile['prefersStepByStep'] as bool? ?? true;
      detailLevel = profile['detailLevel'] as int? ?? 2;
    });
  }

  Future<void> loadTutorSnapshot() async {
    try {
      final snapshot = await _dataService.loadTutorSnapshot();
      if (!_isMounted() || snapshot == null) return;
      _setState(() {
        topicStates = ((snapshot['topicStates'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        memories = ((snapshot['memories'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        activePlan = snapshot['latestPlan'] is Map
            ? Map<String, dynamic>.from(snapshot['latestPlan'] as Map)
            : null;
        reviewCount = (snapshot['reviewCount'] as num?)?.toInt() ?? 0;
        snapshotLoading = false;
      });
    } catch (_) {
      if (_isMounted()) _setState(() => snapshotLoading = false);
    }
  }

  Future<void> loadChatHistory() async {
    final sessions = await _dataService.loadChatHistory();
    if (!_isMounted()) return;
    _setState(() {
      chatHistory = sessions
          .whereType<Map>()
          .map((s) => Map<String, dynamic>.from(s))
          .toList();
    });
  }

  Future<void> restoreSession(String id) async {
    final msgs = await _dataService.restoreSession(id);
    if (!_isMounted()) return;
    _setState(() {
      sessionId = id;
      conversationItems.clear();
      for (final m in msgs) {
        if (m is Map) {
          final isUser = m['isUser'] as bool? ?? false;
          final text = m['messageText'] as String? ?? '';
          conversationItems.add(TextItem(text: text, isUser: isUser));
        }
      }
    });
    _onScrollDown.call();
  }

  Future<void> createAdaptivePlan(String? goalText) async {
    final payload = await _dataService.createAdaptivePlan(
      goal: (goalText?.trim().isEmpty ?? true) ? null : goalText?.trim(),
      subjectName: topicStates.isNotEmpty
          ? topicStates.first['subjectName']?.toString()
          : null,
      studyMode: studyMode,
    );
    if (!_isMounted()) return;
    if (payload?['success'] == true && payload?['plan'] is Map) {
      _setState(() {
        activePlan = Map<String, dynamic>.from(payload!['plan'] as Map);
      });
      _onShowError.call('Adaptive study plan updated.');
      await loadTutorSnapshot();
      return;
    }
    final errMsg = (payload?['errors'] as List?)?.cast<String>().join(', ');
    _onShowError(
        errMsg?.isNotEmpty == true ? errMsg! : 'Could not build a plan.');
  }

  Future<void> saveLearningProfile({
    required String learningStyle,
    required bool prefersExamples,
    required bool prefersStepByStep,
    required int detailLevel,
  }) async {
    _setState(() => profileSaving = true);
    try {
      final payload = await _dataService.saveLearningProfile(
        learningStyle: learningStyle,
        prefersExamples: prefersExamples,
        prefersStepByStep: prefersStepByStep,
        detailLevel: detailLevel,
      );
      if (payload?['success'] != true) {
        final errMsg =
            (payload?['errors'] as List?)?.map((e) => e.toString()).join(', ');
        if (_isMounted()) {
          _onShowError(errMsg?.isNotEmpty == true
              ? errMsg!
              : 'Could not save preferences.');
        }
        return;
      }
      if (!_isMounted()) return;
      _setState(() {
        this.learningStyle = learningStyle;
        this.prefersExamples = prefersExamples;
        this.prefersStepByStep = prefersStepByStep;
        this.detailLevel = detailLevel;
      });
      _onShowError.call('Tutor preferences updated.');
    } finally {
      if (_isMounted()) _setState(() => profileSaving = false);
    }
  }

  void setStudyMode(String mode) => _setState(() => studyMode = mode);
  void toggleInsights() => _setState(() => showInsights = !showInsights);
  void newConversation() {
    _setState(() {
      sessionId = null;
      conversationItems.clear();
    });
  }
}
