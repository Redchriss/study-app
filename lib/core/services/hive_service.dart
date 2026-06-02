import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../graphql/queries/queries.dart';
import '../storage/secure_storage.dart';
import 'scanner_stream_service.dart';

class HiveService {
  static const String _quizAttemptBoxName = 'quiz_attempts';
  static const String _pendingQuizBoxName = 'pending_quiz_submissions';
  static const String _pendingScanBoxName = 'pending_scanner_submissions';

  static late Box _quizAttemptBox;
  static late Box _pendingQuizBox;
  static late Box _pendingScanBox;
  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    _quizAttemptBox = await Hive.openBox(_quizAttemptBoxName);
    _pendingQuizBox = await Hive.openBox(_pendingQuizBoxName);
    _pendingScanBox = await Hive.openBox(_pendingScanBoxName);
    _initialized = true;
  }

  // ── Quiz attempt persistence (Issue 1) ──

  static void saveQuizAttempt(
    String slug, {
    required Map<String, String?> answers,
    required int time,
    String? attemptId,
  }) {
    _quizAttemptBox.put('quiz_pending_$slug', {
      'answers': answers.map((k, v) => MapEntry(k, v ?? '')),
      'time': time,
      if (attemptId != null) 'attemptId': attemptId,
    });
  }

  static Map? getSavedQuizAttempt(String slug) {
    return _quizAttemptBox.get('quiz_pending_$slug') as Map?;
  }

  static void clearQuizAttempt(String slug) {
    _quizAttemptBox.delete('quiz_pending_$slug');
  }

  // ── Pending quiz submission queue (Issue 2) ──

  static bool hasPendingQuizSubmissions() {
    final q = _pendingQuizBox.get('queue');
    return q != null && (q as List).isNotEmpty;
  }

  static int pendingQuizCount() {
    final q = _pendingQuizBox.get('queue');
    if (q == null) return 0;
    return (q as List).length;
  }

  static void enqueueQuizSubmission(Map<String, dynamic> submission) {
    final list = _pendingQuizBox.get('queue', defaultValue: <Map>[]) as List;
    list.add(submission);
    _pendingQuizBox.put('queue', list);
  }

  static List<Map<String, dynamic>> getPendingQuizSubmissions() {
    return (_pendingQuizBox.get('queue', defaultValue: <Map>[]) as List)
        .cast<Map<String, dynamic>>();
  }

  static void removePendingQuizSubmission(int index) {
    final list = _pendingQuizBox.get('queue', defaultValue: <Map>[]) as List;
    if (index >= list.length) return;
    list.removeAt(index);
    if (list.isEmpty) {
      _pendingQuizBox.delete('queue');
    } else {
      _pendingQuizBox.put('queue', list);
    }
  }

  static Future<void> retryPendingQuizSubmissions(GraphQLClient client) async {
    final submissions = getPendingQuizSubmissions();
    if (submissions.isEmpty) return;

    final toRemove = <int>[];
    for (int i = 0; i < submissions.length; i++) {
      final s = submissions[i];
      try {
        final result = await client.mutate(MutationOptions(
          document: gql(kSubmitQuizAttempt),
          variables: {
            'attemptId': s['attemptId'],
            'answers': s['answers'],
            'timeTakenSeconds': s['timeTakenSeconds'],
          },
        ));
        if (!result.hasException &&
            result.data?['submitQuizAttempt']?['success'] == true) {
          toRemove.add(i);
        }
      } catch (err) {
        debugPrint('HiveService: retry quiz submission failed: $err');
      }
    }
    for (final i in toRemove.reversed) {
      removePendingQuizSubmission(i);
    }
  }

  // ── Pending scanner submission queue (Issue 3) ──

  static bool hasPendingScanSubmissions() {
    final q = _pendingScanBox.get('queue');
    return q != null && (q as List).isNotEmpty;
  }

  static int pendingScanCount() {
    final q = _pendingScanBox.get('queue');
    if (q == null) return 0;
    return (q as List).length;
  }

  static void enqueueScanSubmission(Map<String, dynamic> scan) {
    final list = _pendingScanBox.get('queue', defaultValue: <Map>[]) as List;
    list.add(scan);
    _pendingScanBox.put('queue', list);
  }

  static List<Map<String, dynamic>> getPendingScanSubmissions() {
    return (_pendingScanBox.get('queue', defaultValue: <Map>[]) as List)
        .cast<Map<String, dynamic>>();
  }

  static void removePendingScanSubmission(int index) {
    final list = _pendingScanBox.get('queue', defaultValue: <Map>[]) as List;
    if (index >= list.length) return;
    list.removeAt(index);
    if (list.isEmpty) {
      _pendingScanBox.delete('queue');
    } else {
      _pendingScanBox.put('queue', list);
    }
  }

  static Future<void> retryPendingScans() async {
    final scans = getPendingScanSubmissions();
    if (scans.isEmpty) return;

    final token = await SecureStorage.getToken();
    if (token == null) return;

    final toRemove = <int>[];
    for (int i = 0; i < scans.length; i++) {
      final s = scans[i];
      final imagePath = s['imagePath'] as String?;
      if (imagePath == null || !File(imagePath).existsSync()) {
        toRemove.add(i);
        continue;
      }
      try {
        final bytes = File(imagePath).readAsBytesSync();
        if (bytes.length > 5 * 1024 * 1024) {
          toRemove.add(i);
          continue;
        }
        final b64 = base64Encode(bytes);
        final service = ScannerStreamService();
        final result = await service.send(
          imageBase64: b64,
          fileName: imagePath.split('/').last,
          subject: s['subject'] as String?,
          educationLevel: s['educationLevel'] as String?,
          examType: s['examType'] as String? ?? '',
          year: s['year'] as String? ?? '',
          token: token,
          onProgress: (_) {},
          onError: (_) {},
        );
        if (result != null) {
          toRemove.add(i);
        }
      } catch (err) {
        debugPrint('HiveService: retry scan failed: $err');
      }
    }
    for (final i in toRemove.reversed) {
      removePendingScanSubmission(i);
    }
  }

  // ── Aggregate ──

  static int totalPendingCount() {
    return pendingQuizCount() + pendingScanCount();
  }

  static bool hasAnyPending() {
    return hasPendingQuizSubmissions() || hasPendingScanSubmissions();
  }

  static Future<void> retryAll(GraphQLClient client) async {
    await retryPendingQuizSubmissions(client);
    await retryPendingScans();
  }
}
