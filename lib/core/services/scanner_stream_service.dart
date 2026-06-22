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
    http.Client? httpClient,
  }) async {
    final client = httpClient ?? http.Client();
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

      if (response.statusCode == 401) {
        onError('Your session has expired. Please log in again.');
        return null;
      }
      if (response.statusCode != 200) {
        onError('Connection error (${response.statusCode}). Please try again.');
        return null;
      }

      // Decode and split on line boundaries across network chunks. SSE events
      // here can be large (the final `done` payload is several KB of JSON) and
      // a single event may arrive split across multiple chunks. Splitting each
      // chunk independently risks losing the part of a `data:` line that lands
      // in the next chunk; LineSplitter reassembles partial lines so the JSON
      // is never truncated.
      final lines = response.stream
          .timeout(const Duration(seconds: 120))
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      String eventType = '';
      final dataBuffer = StringBuffer();

      await for (final line in lines) {
        if (line.startsWith('event: ')) {
          eventType = line.substring(7).trim();
          dataBuffer.clear();
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
          dataBuffer.clear();
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
