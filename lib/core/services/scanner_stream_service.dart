import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';

class ScannerStreamService {
  Future<Map<String, dynamic>?> send({
    required String imageBase64,
    required String fileName,
    required String? subject,
    required String? educationLevel,
    required String examType,
    required String year,
    required String token,
    required void Function(String) onProgress,
    required void Function(String) onError,
  }) async {
    final client = http.Client();
    try {
      final request = http.StreamedRequest(
        'POST',
        Uri.parse(ApiEndpoints.scannerStream),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'text/event-stream';
      request.sink.add(utf8.encode(jsonEncode({
        'imageBase64': imageBase64,
        'fileName': fileName,
        'subject': subject?.trim() ?? '',
        'educationLevel': educationLevel ?? 'secondary',
        'examType': examType.trim(),
        'year': int.tryParse(year),
      })));
      request.sink.close();

      final response = await client.send(request);
      final lines = response.stream
          .transform(utf8.decoder)
          .timeout(const Duration(seconds: 120));

      String eventType = '';
      StringBuffer dataBuffer = StringBuffer();

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
                case 'progress':
                  onProgress(payload['status'] as String? ?? '');
                case 'done':
                  return payload;
                case 'error':
                  onError(
                      payload['message'] as String? ?? 'Something went wrong.');
                  return null;
              }
            } catch (_) {
              debugPrint(
                  'Scanner Stream: failed to parse SSE event: $eventType $data');
            }
            eventType = '';
            dataBuffer = StringBuffer();
          }
        }
      }
    } on TimeoutException {
      onError('Scanner timed out after 120 seconds. Please try again.');
    } finally {
      client.close();
    }
    return null;
  }
}
