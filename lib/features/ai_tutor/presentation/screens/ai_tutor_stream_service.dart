import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';

class AiTutorStreamService {
  Future<void> sendStream({
    required String text,
    required String? sessionId,
    required String studyMode,
    required String token,
    String? clientInstructions,
    required http.Client httpClient,
    required void Function(String) onToken,
    required void Function(String) onAddMessage,
    required void Function(String) onSessionId,
    required void Function(String) onError,
    required VoidCallback onScrollDown,
  }) async {
    final request = http.StreamedRequest(
      'POST',
      Uri.parse(ApiEndpoints.aiStream),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Content-Type'] = 'application/json';
    request.headers['Accept'] = 'text/event-stream';
    request.sink.add(utf8.encode(jsonEncode({
      'message': text,
      'session_id': sessionId,
      'study_mode': studyMode,
      if (clientInstructions != null) 'client_instructions': clientInstructions,
    })));
    request.sink.close();

    final response = await httpClient.send(request);
    final lines = response.stream.transform(utf8.decoder);
    String eventType = '';
    StringBuffer dataBuffer = StringBuffer();
    String streamingText = '';

    await for (final chunk in lines) {
      for (final line in chunk.split('\n')) {
        if (line.startsWith('event: ')) {
          eventType = line.substring(7).trim();
          dataBuffer = StringBuffer();
        } else if (line.startsWith('data: ')) {
          dataBuffer.write(line.substring(6));
        } else if (line.isEmpty && eventType.isNotEmpty) {
          final data = dataBuffer.toString();
          try {
            final payload = jsonDecode(data) as Map<String, dynamic>;
            switch (eventType) {
              case 'token':
                final t = payload['text'] as String? ?? '';
                streamingText += t;
                onToken(t);
                onScrollDown();
              case 'done':
                onAddMessage(streamingText);
                streamingText = '';
              case 'meta':
                if (payload['session_id'] != null) {
                  onSessionId(payload['session_id'].toString());
                }
              case 'error':
                onError(payload['message'] ?? 'Something went wrong.');
            }
          } catch (_) {
            debugPrint('AI Tutor: failed to parse SSE event: $eventType $data');
          }
          eventType = '';
          dataBuffer = StringBuffer();
        }
      }
    }
  }
}
