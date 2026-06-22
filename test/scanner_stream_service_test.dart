import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:studyapp/core/services/scanner_stream_service.dart';

/// Emits [bytes] in small fixed-size chunks to simulate a network that splits
/// a single SSE event across multiple TCP chunks (including mid-JSON splits).
Stream<List<int>> _chunked(List<int> bytes, {int size = 16}) async* {
  for (var i = 0; i < bytes.length; i += size) {
    yield bytes.sublist(i, math.min(i + size, bytes.length));
  }
}

void main() {
  group('ScannerStreamService SSE parsing', () {
    test('reassembles a large done payload split across network chunks',
        () async {
      // A realistic, large `done` payload — several hundred bytes of JSON that
      // will be split mid-line by the 16-byte chunking below.
      final donePayload = {
        'session': {'id': 14, 'status': 'solved', 'creditCharged': true},
        'solutions': [
          {
            'questionNumber': '1',
            'questionText': 'Solve for x. 2x + 5 = 13',
            'answer': 'x = 4',
            'explanation':
                'Subtract 5 from both sides, then divide by 2 to isolate x.',
            'confidence': 0.98,
            'steps': [
              'Start with 2x + 5 = 13.',
              'Subtract 5 from both sides: 2x = 8.',
              'Divide both sides by 2: x = 4.',
            ],
            'marks': 2,
          },
          {
            'questionNumber': '2',
            'questionText': 'What is 7 multiplied by 6?',
            'answer': '42',
            'explanation': 'Basic multiplication of 7 and 6.',
            'confidence': 0.99,
            'steps': ['7 x 6 = 42.'],
            'marks': 1,
          },
        ],
        'creditsCost': 1,
        'creditsRemaining': 1,
      };

      final sse = 'event: progress\n'
          'data: ${jsonEncode({
            'status': 'Extracting questions from document...',
            'stage': 'extracting'
          })}\n'
          '\n'
          'event: progress\n'
          'data: ${jsonEncode({
            'status': 'Solving 2 questions...',
            'stage': 'solving'
          })}\n'
          '\n'
          'event: done\n'
          'data: ${jsonEncode(donePayload)}\n'
          '\n';

      final mock = MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(
          _chunked(utf8.encode(sse)),
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      });

      final progressUpdates = <String>[];
      String? errorMessage;

      final result = await ScannerStreamService().send(
        imageBase64: 'aGVsbG8=',
        fileName: 'scan.png',
        subject: 'Mathematics',
        educationLevel: 'secondary',
        examType: 'practice',
        year: '2024',
        token: 'test-token',
        onProgress: progressUpdates.add,
        onError: (m) => errorMessage = m,
        httpClient: mock,
      );

      expect(errorMessage, isNull);
      expect(result, isNotNull);

      final solutions = result!['solutions'] as List;
      expect(solutions, hasLength(2));
      expect((solutions.first as Map)['answer'], 'x = 4');
      expect((solutions.last as Map)['answer'], '42');
      expect(result['creditsRemaining'], 1);

      // Progress events surfaced before the final result.
      expect(
          progressUpdates, contains('Extracting questions from document...'));
      expect(progressUpdates, contains('Solving 2 questions...'));
    });

    test('surfaces an SSE error event as an error callback', () async {
      const sse = 'event: error\n'
          'data: {"message": "Could not generate solutions."}\n'
          '\n';

      final mock = MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(
          _chunked(utf8.encode(sse)),
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      });

      String? errorMessage;
      final result = await ScannerStreamService().send(
        imageBase64: 'aGVsbG8=',
        fileName: 'scan.png',
        subject: 'Mathematics',
        educationLevel: 'secondary',
        examType: 'practice',
        year: '2024',
        token: 'test-token',
        onProgress: (_) {},
        onError: (m) => errorMessage = m,
        httpClient: mock,
      );

      expect(result, isNull);
      expect(errorMessage, 'Could not generate solutions.');
    });

    test('reports a clear error on a non-200 response', () async {
      final mock = MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(const Stream.empty(), 502);
      });

      String? errorMessage;
      final result = await ScannerStreamService().send(
        imageBase64: 'aGVsbG8=',
        fileName: 'scan.png',
        subject: 'Mathematics',
        educationLevel: 'secondary',
        examType: 'practice',
        year: '2024',
        token: 'test-token',
        onProgress: (_) {},
        onError: (m) => errorMessage = m,
        httpClient: mock,
      );

      expect(result, isNull);
      expect(errorMessage, contains('502'));
    });
  });
}
