import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:genui/genui.dart' hide TextPart;
import 'package:genui/genui.dart' as genui;

import '../screens/ai_tutor_data_service.dart';
import '../screens/ai_tutor_stream_service.dart';

String extractMessageText(ChatMessage msg) {
  final buffer = StringBuffer();
  for (final part in msg.parts) {
    if (part.isUiInteractionPart) {
      buffer.write(part.asUiInteractionPart!.interaction);
    } else if (part is genui.TextPart) {
      buffer.write(part.text);
    }
  }
  return buffer.toString();
}

Future<void> sendTutorStream({
  required String text,
  required String? sessionId,
  required String studyMode,
  required String token,
  required String clientInstructions,
  required AiTutorStreamService streamService,
  required A2uiTransportAdapter transport,
  required http.Client httpClient,
  required void Function(String) onToken,
  required void Function(String) onAddMessage,
  required void Function(String) onSessionId,
  required void Function(String) onError,
  required VoidCallback onScrollDown,
}) async {
  try {
    await streamService.sendStream(
      text: text,
      sessionId: sessionId,
      studyMode: studyMode,
      token: token,
      clientInstructions: clientInstructions,
      httpClient: httpClient,
      onToken: onToken,
      onAddMessage: onAddMessage,
      onSessionId: onSessionId,
      onError: onError,
      onScrollDown: onScrollDown,
    );
  } catch (_) {
    onError('Connection lost. Please try again.');
  }
}

Future<void> handleLoadManagerTutorSnapshot({
  required AiTutorDataService dataService,
  required bool Function() isMounted,
  required void Function(
    List<Map<String, dynamic>> topicStates,
    List<Map<String, dynamic>> memories,
    Map<String, dynamic>? activePlan,
    int reviewCount,
  ) onSnapshot,
  required VoidCallback onError,
}) async {
  try {
    final snapshot = await dataService.loadTutorSnapshot();
    if (!isMounted() || snapshot == null) return;
    final topicStates = ((snapshot['topicStates'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final memories = ((snapshot['memories'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final activePlan = snapshot['latestPlan'] is Map
        ? Map<String, dynamic>.from(snapshot['latestPlan'] as Map)
        : null;
    final reviewCount = (snapshot['reviewCount'] as num?)?.toInt() ?? 0;
    onSnapshot(topicStates, memories, activePlan, reviewCount);
  } catch (_) {
    onError();
  }
}

Future<void> handleSaveManagerLearningProfile({
  required AiTutorDataService dataService,
  required String learningStyle,
  required bool prefersExamples,
  required bool prefersStepByStep,
  required int detailLevel,
  required bool Function() isMounted,
  required void Function() onStart,
  required void Function() onSuccess,
  required void Function(String) onShowError,
  required void Function() onFinally,
}) async {
  onStart();
  try {
    final payload = await dataService.saveLearningProfile(
      learningStyle: learningStyle,
      prefersExamples: prefersExamples,
      prefersStepByStep: prefersStepByStep,
      detailLevel: detailLevel,
    );
    if (payload?['success'] != true) {
      final errMsg =
          (payload?['errors'] as List?)?.map((e) => e.toString()).join(', ');
      if (isMounted()) {
        onShowError(errMsg?.isNotEmpty == true
            ? errMsg!
            : 'Could not save preferences.');
      }
      return;
    }
    if (!isMounted()) return;
    onSuccess();
    onShowError('Tutor preferences updated.');
  } finally {
    if (isMounted()) onFinally();
  }
}
