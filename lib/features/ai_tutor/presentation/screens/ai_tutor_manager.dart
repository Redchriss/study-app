import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../../core/storage/secure_storage.dart';
import 'ai_tutor_data_service.dart';
import 'ai_tutor_stream_service.dart';

class AiTutorManager {
  late void Function(VoidCallback) _setState;
  late bool Function() _isMounted;
  late VoidCallback _onScrollDown;
  late void Function(String) _onShowError;
  late AiTutorDataService _dataService;
  late AiTutorStreamService _streamService;

  List<Map<String, dynamic>> messages = [];
  String? sessionId;
  bool sending = false;
  bool streaming = false;
  String streamingText = '';
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
  }

  Map<String, dynamic> _messageMap(String text, bool isUser) => {
    'messageText': text,
    if (!isUser) 'displayText': text,
    'isUser': isUser,
    'timestamp': DateTime.now().toIso8601String(),
  };

  void _resetStream() => _setState(() {
    sending = false;
    streaming = false;
    streamingText = '';
  });

  void _addAiMessage(String msg) {
    _setState(() {
      messages.add(_messageMap(msg, false));
      streamingText = '';
      sending = false;
      streaming = false;
    });
    loadTutorSnapshot();
  }

  void addUserMessage(String text) {
    _setState(() {
      messages.add(_messageMap(text, true));
      sending = true;
      streaming = true;
      streamingText = '';
    });
  }

  Future<void> send(String text, http.Client httpClient) async {
    if (text.isEmpty || sending) return;
    addUserMessage(text);
    _onScrollDown.call();
    final token = await SecureStorage.getToken();
    if (token == null) { _resetStream(); return; }
    try {
      await _streamService.sendStream(
        text: text,
        sessionId: sessionId,
        studyMode: studyMode,
        token: token,
        httpClient: httpClient,
        onToken: (t) => _setState(() => streamingText += t),
        onAddMessage: _addAiMessage,
        onSessionId: (id) => sessionId = id,
        onError: (msg) {
          if (_isMounted()) { _resetStream(); _onShowError(msg); }
        },
        onScrollDown: _onScrollDown,
      );
      if (!_isMounted() || !streaming) return;
      if (streamingText.trim().isNotEmpty) {
        _addAiMessage(streamingText.trim());
        _onScrollDown.call();
      } else {
        _resetStream();
        _onShowError.call('Tutor response ended unexpectedly. Please try again.');
      }
    } catch (_) {
      if (!_isMounted()) return;
      _resetStream();
      _onShowError.call('Connection lost. Please try again.');
    }
  }

  Future<void> loadLearningProfile() async {
    try {
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
    } catch (_) {}
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
    try {
      final sessions = await _dataService.loadChatHistory();
      if (!_isMounted()) return;
      _setState(() {
        chatHistory = sessions
            .whereType<Map>()
            .map((s) => Map<String, dynamic>.from(s))
            .toList();
      });
    } catch (_) {}
  }

  Future<void> restoreSession(String id) async {
    try {
      final msgs = await _dataService.restoreSession(id);
      if (!_isMounted()) return;
      _setState(() {
        sessionId = id;
        messages.clear();
        for (final m in msgs) {
          if (m is Map) messages.add(Map<String, dynamic>.from(m));
        }
      });
      _onScrollDown.call();
    } catch (_) {}
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
    _onShowError(errMsg?.isNotEmpty == true ? errMsg! : 'Could not build a plan.');
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
        final errMsg = (payload?['errors'] as List?)?.map((e) => e.toString()).join(', ');
        if (_isMounted()) _onShowError(errMsg?.isNotEmpty == true ? errMsg! : 'Could not save preferences.');
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
      messages.clear();
    });
  }
}
