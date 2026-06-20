import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/api_endpoints.dart';

class AgentStreamService {
  Future<void> sendStream({
    required String text,
    required String? sessionId,
    required String studyMode,
    required String token,
    String? clientInstructions,
    String? checkpointText,
    required http.Client httpClient,
    required void Function(String) onToken,
    required void Function(String) onAddMessage,
    required void Function(String) onSessionId,
    required void Function(String) onError,
    required VoidCallback onScrollDown,
    void Function(int)? onJobId,
    void Function(Map<String, dynamic>)? onSpec,
    void Function(int)? onFreeRemaining,
  }) async {
    await _consumeSse(
      request: _streamRequest(
        token: token,
        sessionId: sessionId,
        studyMode: studyMode,
        text: text,
        clientInstructions: clientInstructions,
        checkpointText: checkpointText,
      ),
      httpClient: httpClient,
      onToken: onToken,
      onAddMessage: onAddMessage,
      onSessionId: onSessionId,
      onError: onError,
      onScrollDown: onScrollDown,
      onJobId: onJobId,
      onSpec: onSpec,
      onFreeRemaining: onFreeRemaining,
    );
  }

  Future<void> replayJob({
    required int jobId,
    required String token,
    required http.Client httpClient,
    required void Function(String) onToken,
    required void Function(String) onAddMessage,
    required void Function(String) onSessionId,
    required void Function(String) onError,
    required VoidCallback onScrollDown,
    void Function(int)? onJobId,
    void Function(Map<String, dynamic>)? onSpec,
    void Function(int)? onFreeRemaining,
  }) async {
    final request = http.Request(
      'GET',
      Uri.parse(ApiEndpoints.agentReplay(jobId)),
    )
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'text/event-stream';
    await _consumeSse(
      request: request,
      httpClient: httpClient,
      onToken: onToken,
      onAddMessage: onAddMessage,
      onSessionId: onSessionId,
      onError: onError,
      onScrollDown: onScrollDown,
      onJobId: onJobId,
      onSpec: onSpec,
      onFreeRemaining: onFreeRemaining,
    );
  }

  http.BaseRequest _streamRequest({
    required String token,
    required String? sessionId,
    required String studyMode,
    required String text,
    String? clientInstructions,
    String? checkpointText,
  }) {
    final request = http.StreamedRequest(
      'POST',
      Uri.parse(ApiEndpoints.agentStream),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Content-Type'] = 'application/json';
    request.headers['Accept'] = 'text/event-stream';
    final body = <String, dynamic>{
      'message': text,
      'session_id': sessionId,
      'mode': 'study',
      'study_mode': studyMode,
      if (clientInstructions != null) 'client_instructions': clientInstructions,
      if (checkpointText != null && checkpointText.isNotEmpty)
        'checkpoint': checkpointText,
    };
    request.sink.add(utf8.encode(jsonEncode(body)));
    request.sink.close();
    return request;
  }

  Future<void> _consumeSse({
    required http.BaseRequest request,
    required http.Client httpClient,
    required void Function(String) onToken,
    required void Function(String) onAddMessage,
    required void Function(String) onSessionId,
    required void Function(String) onError,
    required VoidCallback onScrollDown,
    void Function(int)? onJobId,
    void Function(Map<String, dynamic>)? onSpec,
    void Function(int)? onFreeRemaining,
  }) async {
    final response = await httpClient.send(request);
    final lines = response.stream
        .transform(utf8.decoder)
        .timeout(const Duration(seconds: 90));
    String eventType = '';
    StringBuffer dataBuffer = StringBuffer();
    String streamingText = '';

    try {
      await for (final chunk in lines) {
        for (final line in chunk.split('\n')) {
          if (line.startsWith('event: ')) {
            eventType = line.substring(7).trim();
            dataBuffer = StringBuffer();
            continue;
          }
          if (line.startsWith('data: ')) {
            dataBuffer.write(line.substring(6));
            continue;
          }
          if (line.isEmpty && eventType.isNotEmpty) {
            streamingText = _handleEvent(
              eventType: eventType,
              data: dataBuffer.toString(),
              streamingText: streamingText,
              onToken: onToken,
              onAddMessage: onAddMessage,
              onSessionId: onSessionId,
              onError: onError,
              onScrollDown: onScrollDown,
              onJobId: onJobId,
              onSpec: onSpec,
              onFreeRemaining: onFreeRemaining,
            );
            eventType = '';
            dataBuffer = StringBuffer();
          }
        }
      }
    } on TimeoutException {
      onError('Response timed out. Please try again.');
    }
  }

  String _handleEvent({
    required String eventType,
    required String data,
    required String streamingText,
    required void Function(String) onToken,
    required void Function(String) onAddMessage,
    required void Function(String) onSessionId,
    required void Function(String) onError,
    required VoidCallback onScrollDown,
    void Function(int)? onJobId,
    void Function(Map<String, dynamic>)? onSpec,
    void Function(int)? onFreeRemaining,
  }) {
    try {
      final payload = jsonDecode(data) as Map<String, dynamic>;
      switch (eventType) {
        case 'token':
        case 'assistant':
          final t = payload['text'] as String? ?? '';
          if (t.isNotEmpty) {
            streamingText += t;
            onToken(t);
            onScrollDown();
          }
          final spec = payload['spec'];
          if (spec is Map<String, dynamic>) {
            onSpec?.call(spec);
          }
        case 'done':
          if (streamingText.isNotEmpty) {
            onAddMessage(streamingText);
          }
          streamingText = '';
        case 'meta':
          if (payload['job_id'] != null) {
            onJobId?.call((payload['job_id'] as num).toInt());
          }
          if (payload['session_id'] != null) {
            onSessionId(payload['session_id'].toString());
          }
          if (payload['free_remaining'] != null) {
            onFreeRemaining?.call((payload['free_remaining'] as num).toInt());
          }
        case 'error':
          onError(payload['message']?.toString() ?? 'Something went wrong.');
      }
    } catch (_) {
      debugPrint('Agent: failed to parse SSE event: $eventType $data');
    }
    return streamingText;
  }
}
